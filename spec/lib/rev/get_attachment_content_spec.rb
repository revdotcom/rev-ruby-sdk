require_relative '../../spec_helper'

describe 'GET /attachments/{id}/content' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  filename = './spec/tmp_get_attachment_content'

  before do
    File.delete filename if File.file? filename # clean before
  end

  after do
    File.delete filename if File.file? filename # clean after
  end

  describe 'success' do

    describe 'must save binary content to file' do
      it 'when no representation given' do
        VCR.insert_cassette 'get_attachment_content'
        # we just save mocked binary response body to file and check for existence
        client.save_attachment_content('4QWoFrwBAAABAAAA', filename) # from order TC0380110305
        File.file?(filename).must_equal true

        assert_requested :get, /.*\/api\/v1\/attachments\/4QWoFrwBAAABAAAA\/content/, :times => 1
      end

      it 'using given correct representation' do
        VCR.insert_cassette 'get_attachment_content_as_pdf'

        client.save_attachment_content('4QWoFrwBAAABAAAA', filename, Rev::Attachment::REPRESENTATIONS[:pdf])
        File.file?(filename).must_equal true
        # we don't actually check whether it's PDF - we assume it is. We just supply headers as requested
      end
    end

    it 'must specify Accept-Charset header for plain text' do
      VCR.insert_cassette 'get_attachment_content_as_text'

      client.save_attachment_content('4QWoFrwBAAABAAAA', filename, Rev::Attachment::REPRESENTATIONS[:txt])

      assert_requested :get, /.*\/api\/v1\/attachments\/4QWoFrwBAAABAAAA\/content/, :times => 1 do |req|
        req.headers['Accept-Charset'].must_equal 'utf-8'
      end
    end

    it 'must specify Accept-Charset header for youtube transcript' do
      VCR.insert_cassette 'get_attachment_content_as_youtube_transcript'

      client.save_attachment_content('4QWoFrwBAAABAAAA', filename, Rev::Attachment::REPRESENTATIONS[:youtube])

      assert_requested :get, /.*\/api\/v1\/attachments\/4QWoFrwBAAABAAAA\/content/, :times => 1 do |req|
        req.headers['Accept-Charset'].must_equal 'utf-8'
      end
    end
  end

  it 'must raise NotFoundError when attachment id is invalid' do
    VCR.insert_cassette 'get_attachment_content_with_invalid_id'

    action = lambda { client.save_attachment_content('trololo', filename) }
    action.must_raise Rev::NotFoundError
  end

  # requesting conversion from pdf to :docx from order TC0263917003
  it 'must raise NotAcceptableError when requested representation is not supported by API' do
    VCR.insert_cassette 'get_attachment_content_unacceptable_representation'

    action = lambda { client.save_attachment_content('yw27D3gCAAABAAAA', filename,
      Rev::Attachment::REPRESENTATIONS[:docx]) }
    action.must_raise Rev::NotAcceptableError
  end

  after do
    VCR.eject_cassette
  end
end


