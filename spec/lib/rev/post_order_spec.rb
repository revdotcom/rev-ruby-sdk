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

  let(:credit_card) { Rev::CreditCard.new(
    :number => '4111111111111111',
    :expiration_month => 9,
    :expiration_year => 2023,
    :cardholder => 'Joe Smith',
    :billing_address => billing_address
  )}
  let(:cc_payment) { Rev::Payment.new(Rev::Payment::TYPES[:credit_card], credit_card) }
  let(:saved_cc_payment) { Rev::Payment.new(Rev::Payment::TYPES[:credit_card], :saved_id => 1) }
  let(:balance_payment) { Rev::Payment.new(Rev::Payment::TYPES[:account_balance]) }
  let(:transcription_inputs) {
      inputs = []
      inputs << Rev::Input.new(:external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc')
      inputs << Rev::Input.new(:audio_length => 15, :external_link => 'https://vimeo.com/7976699')
  }
  let(:translation_inputs) {
    inputs = []
    inputs << Rev::Input.new(:word_length => 1000, :uri => 'urn:foxtranslate:inputmedia:SnVwbG9hZHMvMjAxMy0wOS0xNy9lMzk4MWIzNS0wNzM1LTRlMDAtODY1NC1jNWY4ZjE4MzdlMTIvc291cmNlZG9jdW1lbnQucG5n')
  }
  let(:caption_inputs) {
    inputs = []
    inputs << Rev::Input.new(:external_link => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc')
  }
  let(:transcription_options) { Rev::TranscriptionOptions.new(transcription_inputs,
    :verbatim => true, :timestamps => true) }
  let(:translation_options) { Rev::TranslationOptions.new(translation_inputs,
    :source_language_code => 'es', :destination_language_code => 'en') }
  let(:caption_options) {
    Rev::CaptionOptions.new(caption_inputs, :output_file_formats => ['SubRip'])
  }

  it 'must submit order using Credit Card including all attributes' do
    VCR.insert_cassette 'submit_tc_order_with_cc_and_all_attributes'

    request = Rev::OrderRequest.new(
      cc_payment,
      :transcription_options => transcription_options,
      :client_ref => 'XB432423',
      :comment => 'Please work quickly',
      :notification => Rev::Notification.new('http://www.example.com', Rev::Notification::LEVELS[:detailed])
    )

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'TC0520815415'
    expected_body = {
      'payment' => {
        'type' => 'CreditCard',
        'credit_card' => {
          'number' => '4111111111111111',
          'expiration_month' => 9,
          'expiration_year' => 2023,
          'cardholder' => 'Joe Smith',
          'billing_address' => {
            'street' => '123 Pine Lane',
            'street2' => 'Apt D',
            'city' => 'MyTown',
            'state' => 'MN',
            'zip' => '12345',
            'country_alpha2' => 'US'
          }
        }
      },
      'transcription_options' => {
        'inputs'=> [
          { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' },
          { 'audio_length' => 15, 'external_link' => 'https://vimeo.com/7976699' }
        ],
        'verbatim' => true,
        'timestamps' => true
      },
      'client_ref' => 'XB432423',
      'comment' => 'Please work quickly',
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'notification' => {
        'url' => 'http://www.example.com',
        'level' => 'Detailed'
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must place order using saved credit card' do
    VCR.insert_cassette 'submit_tc_order_with_saved_cc'

    request = Rev::OrderRequest.new(
      saved_cc_payment,
      :transcription_options => transcription_options
    )

    new_order_num = client.submit_order(request)

    new_order_num.must_equal 'TC0370955571'
    expected_body = {
      'payment' => {
        'type' => 'CreditCard',
        'credit_card' => {
          'saved_id' => 1
        }
      },
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'transcription_options' => {
        'inputs' => [
          { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' },
          { 'external_link' => 'https://vimeo.com/7976699', 'audio_length'=>15 }
        ],
        'verbatim'=>true,
        'timestamps'=>true
      }
    }
    assert_requested(:post, /.*\/orders/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must place order using account balance' do
    VCR.insert_cassette 'submit_tc_order_with_account_balance'

    request = Rev::OrderRequest.new(
      balance_payment,
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
          { 'external_link' => 'https://vimeo.com/7976699', 'audio_length' => 15 }
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
      balance_payment
    )

    action = lambda { client.submit_order(request) }
    exception = action.must_raise Rev::BadRequestError
    exception.message.must_match '10004: You must specify either translation or transcription options in an order'
    exception.code.must_equal Rev::OrderRequestErrorCodes::TC_OR_TR_OPTIONS_NOT_SPECIFIED
  end

  it 'must submit translation order with options' do
    VCR.insert_cassette 'submit_tr_order'

    request = Rev::OrderRequest.new(
      balance_payment,
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
    
    request = Rev::OrderRequest.new(balance_payment, :caption_options => caption_options)
    
    new_order_num = client.submit_order(request)
    
    new_order_num.must_equal 'CP12345'
    expected_body = {
      'payment' => {
        'type' => 'AccountBalance'
      },
      'priority' => Rev::OrderRequest::PRIORITY[:normal],
      'caption_options' => {
        'inputs'=> [
          { 'external_link' => 'http://www.youtube.com/watch?v=UF8uR6Z6KLc' }
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

  after do
    VCR.eject_cassette
  end

end