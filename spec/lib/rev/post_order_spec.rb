require_relative '../../spec_helper'

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
      inputs << Rev::Input.new(:external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc')
      inputs << Rev::Input.new(:audio_length_seconds => 900, :external_link => 'https://vimeo.com/7976699')
  }
  let(:translation_inputs) {
    inputs = []
    inputs << Rev::Input.new(:word_length => 1000, :uri => 'urn:foxtranslate:inputmedia:SnVwbG9hZHMvMjAxMy0wOS0xNy9lMzk4MWIzNS0wNzM1LTRlMDAtODY1NC1jNWY4ZjE4MzdlMTIvc291cmNlZG9jdW1lbnQucG5n')
  }
  let(:caption_inputs) {
    inputs = []
    inputs << Rev::Input.new(:video_length_seconds => 900, :external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc')
  }
  let(:transcription_options) { Rev::TranscriptionOptions.new(transcription_inputs,
    :verbatim => true, :timestamps => true) }
  let(:translation_options) { Rev::TranslationOptions.new(translation_inputs,
    :source_language_code => 'es', :destination_language_code => 'en') }
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
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'transcription_options' => {
        'inputs' => [
          { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' },
          { 'external_link' => 'https://vimeo.com/7976699', 'audio_length_seconds' => 900 }
        ],
        'verbatim' => true,
        'timestamps' => true
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
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
        'priority' => Rev::OrderRequest::PRIORITY[:normal],
        'transcription_options' => {
            'inputs' => [
                { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' },
                { 'external_link' => 'https://vimeo.com/7976699', 'audio_length_seconds' => 900 }
            ],
            'verbatim' => true,
            'timestamps' => true
        }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must raise BadRequest error in case of request validation failure' do
    VCR.insert_cassette 'submit_tc_order_with_invalid_request'

    # example - missing transcription options
    request = Rev::OrderRequest.new(
    )

    action = lambda { client.submit_order(request) }
    exception = action.must_raise Rev::BadRequestError
    exception.message.must_match '10004: You must specify either translation or transcription options in an order'
    exception.code.must_equal Rev::OrderRequestErrorCodes::TC_OR_TR_OPTIONS_NOT_SPECIFIED
  end

  it 'must submit translation order with options' do
    VCR.insert_cassette 'submit_tr_order'

    request = Rev::OrderRequest.new(
      :translation_options => translation_options
    )

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'TR0235803277'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'translation_options' => {
        'inputs'=> [
          { 'word_length' => 1000, 'uri' => 'urn:foxtranslate:inputmedia:SnVwbG9hZHMvMjAxMy0wOS0xNy9lMzk4MWIzNS0wNzM1LTRlMDAtODY1NC1jNWY4ZjE4MzdlMTIvc291cmNlZG9jdW1lbnQucG5n' },
        ],
        'source_language_code' => 'es',
        'destination_language_code' => 'en'
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
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
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'caption_options' => {
        'inputs'=> [
          { 'video_length_seconds' => 900, 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' }
        ],
        'output_file_formats' => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:subrip]]
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must submit subtitle order with options' do
    VCR.insert_cassette 'submit_su_order'

    request = Rev::OrderRequest.new(:caption_options => subtitle_options)

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'CP12345'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'caption_options' => {
        'inputs'=> [
          { 'video_length_seconds' => 900, 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' }
        ],
        'subtitle_languages' => ['es','it'],
        'output_file_formats' => [Rev::CaptionOptions::OUTPUT_FILE_FORMATS[:subrip]]
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  after do
    VCR.eject_cassette
  end

end
