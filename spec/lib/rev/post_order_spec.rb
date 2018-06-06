require_relative '../../spec_helper'
require 'pry'

describe 'POST /orders' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  # some defaults we use often
  let(:billing_address) { Rev::BillingAddress.new(
    :street => '123 Pine Lane',
    :street2 => 'Apt D',
    :city => 'MyTown',
    :state => 'MN',
    :zip => '12345',
    :country_alpha2 => 'US'
  )}

  let(:balance_payment) { Rev::Payment.new(Rev::Payment::TYPES[:account_balance]) }
  let(:transcription_inputs) {
      inputs = []
      inputs << Rev::Input.new(:external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', accents: ['AmericanNeutral', 'Australian'])
      inputs << Rev::Input.new(:audio_length_seconds => 900, :external_link => 'https://vimeo.com/7976699', speaker_names: ['Billy', 'Bob'], glossary: ['Sandwich'])
  }
  let(:caption_inputs) {
    inputs = []
    inputs << Rev::Input.new(:video_length_seconds => 900, :external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', speaker_names: ['Billy', 'Bob'], glossary: ['Sandwich'])
  }
  let(:transcription_options) { Rev::TranscriptionOptions.new(transcription_inputs,
    :verbatim => true, :timestamps => true) }
  let(:caption_options) {
    Rev::CaptionOptions.new(caption_inputs, :output_file_formats => ['SubRip'])
  }
  let(:subtitle_options) {
    Rev::CaptionOptions.new(caption_inputs, :subtitle_languages => ['es','it'],
    :output_file_formats => ['SubRip'])
  }

  it 'must place order using account balance' do
    VCR.insert_cassette 'submit_tc_order_with_account_balance'

    request = Rev::OrderRequest.new(
      :transcription_options => transcription_options
    )

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'TC0406615008'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'non_standard_tat_guarantee' => false,
      'transcription_options' => {
        'inputs' => [
          { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', 'accents' => ['AmericanNeutral', 'Australian']},
          { 'external_link' => 'https://vimeo.com/7976699', 'audio_length_seconds' => 900, 'speaker_names' => ['Billy', 'Bob'], 'glossary' => ['Sandwich'] }
        ],
        'verbatim' => true,
        'timestamps' => true
      }
    }
    assert_order_placement_success(expected_body)
  end

  it 'must default to account balance if payment property not set' do
    VCR.insert_cassette 'submit_tc_order_without_specifying_payment'

    request = Rev::OrderRequest.new(
        :transcription_options => transcription_options
    )

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'TC0406615008'
    expected_body = {
        'payment' => {
            'type' => 'AccountBalance'
        },
        'non_standard_tat_guarantee' => false,
        'transcription_options' => {
            'inputs' => [
                { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', 'accents' => ['AmericanNeutral', 'Australian']},
                { 'external_link' => 'https://vimeo.com/7976699', 'audio_length_seconds' => 900, 'speaker_names' => ['Billy', 'Bob'], 'glossary' => ['Sandwich'] }
            ],
            'verbatim' => true,
            'timestamps' => true
        }
    }
    assert_order_placement_success(expected_body)
  end

  it 'must raise BadRequest error in case of request validation failure' do
    VCR.insert_cassette 'submit_tc_order_with_invalid_request'

    # example - missing transcription options
    request = Rev::OrderRequest.new

    action = lambda { client.submit_order(request) }
    exception = action.must_raise Rev::BadRequestError
    exception.message.must_match '10004: You must specify either transcription or caption options in an order'
    exception.code.must_equal Rev::OrderRequestErrorCodes::OPTIONS_NOT_SPECIFIED
  end

  it 'must submit caption order with options' do
    VCR.insert_cassette 'submit_cp_order'

    request = Rev::OrderRequest.new(:caption_options => caption_options)

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'CP12345'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'non_standard_tat_guarantee' => false,
      'caption_options' => {
        'inputs'=> [
          { 'video_length_seconds' => 900, 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', 'speaker_names' => ['Billy', 'Bob'], 'glossary' => ['Sandwich'] }
        ],
        'output_file_formats' => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:subrip]]
      }
    }
    assert_order_placement_success(expected_body)
  end

  it 'must submit subtitle order with options' do
    VCR.insert_cassette 'submit_su_order'

    request = Rev::OrderRequest.new(:caption_options => subtitle_options)

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'CP56789'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'non_standard_tat_guarantee' => false,
      'caption_options' => {
        'inputs'=> [
          { 'video_length_seconds' => 900, 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc', 'speaker_names' => ['Billy', 'Bob'], 'glossary' => ['Sandwich'] }
        ],
        'subtitle_languages' => ['es','it'],
        'output_file_formats' => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:subrip]]
      }
    }
    assert_order_placement_success(expected_body)
  end

  after do
    VCR.eject_cassette
  end

  private

  def assert_order_placement_success(expected_body)
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'].must_equal 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

end
