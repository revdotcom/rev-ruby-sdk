require_relative '../../spec_helper'
require 'base64'

describe 'POST /inputs' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  it 'must link external file with explicit content-type and file' do
    VCR.insert_cassette 'link_input_with_all_attributes'

    link = 'http://www.rev.com/content/img/rev/rev_logo_colored_top.png'
    filename = 'sourcedocument.png'
    content_type = 'image/png'
    new_input_location = client.create_input_from_link(link, filename, content_type)

    new_input_location.must_match 'urn:foxtranslate:inputmedia:'
    expected_body = {
      'url' => link,
      'filename' => filename,
      'content_type' => content_type
    }
    assert_requested(:post, /.*\/inputs/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must link external file without content-type and filename' do
    VCR.insert_cassette 'link_input'

    link = 'http://www.rev.com/content/img/rev/rev_logo_colored_top.png'
    new_input_location = client.create_input_from_link(link)

    new_input_location.must_match 'urn:foxtranslate:inputmedia:'
    expected_body = { 'url' => link }
    assert_requested(:post, /.*\/inputs/, :times => 1) do |req|
      req.headers['Content-Type'] == 'application/json'
      actual_body = JSON.load req.body
      actual_body.must_equal expected_body
    end
  end

  it 'must upload source file directly' do
    VCR.insert_cassette 'upload_input'

    filename = './spec/fixtures/sourcedocument.png'
    content_type = 'image/png'

    new_input_location = client.upload_input(filename, content_type)

    new_input_location.must_match 'urn:foxtranslate:inputmedia:'
    expected_body = File.read(filename)
    assert_requested(:post, /.*\/inputs/, :times => 1) do |req|
      req.headers['Content-Type'] == content_type
      req.headers['Content-Disposition'] == 'attachment; filename="sourcedocument.png'
      req.body.must_equal expected_body
    end
  end

  it 'must raise BadRequestError on failure' do
    VCR.insert_cassette 'upload_input_with_invalid_content_type'

    filename = './spec/fixtures/sourcedocument.png'
    content_type = 'trololo'

    action = lambda { client.upload_input(filename, content_type) }
    exception = action.must_raise Rev::BadRequestError
    exception.message.must_match '10001: The content-type explicitly specified in the request is not supported for input media'
    exception.code.must_equal Rev::InputRequestErrorCodes::UNSUPPORTED_CONTENT_TYPE
  end

  after do
    VCR.eject_cassette
  end
end
