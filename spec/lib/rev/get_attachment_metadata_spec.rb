require_relative '../../spec_helper'

describe 'GET /attachments/{id}' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  it 'must retrieve metadata' do
    VCR.insert_cassette 'get_attachment_metadata'

    attachment = client.get_attachment_metadata('LufnCVQCAAAAAAAA')

    assert_requested :get, /.*\/api\/v1\/attachments\/LufnCVQCAAAAAAAA/, :times => 1

    attachment.id.must_equal 'LufnCVQCAAAAAAAA'
    attachment.name.must_equal 'How can I find success in life.mp4'
    attachment.kind.must_equal 'media'
    attachment.audio_length_seconds.must_equal 300
    attachment.links.must_be_instance_of Array
    attachment.links.size.must_equal 1
    attachment.links.first.rel.must_equal 'content'
    attachment.links.first.href.must_equal 'https://www.revtrunk.com/api/v1/attachments/LufnCVQCAAAAAAAA/content'
  end

  it 'must raise NotFoundError when attachment id is invalid' do
    VCR.insert_cassette 'get_attachment_with_invalid_id'

    action = lambda { client.get_attachment_metadata('trololo') }
    action.must_raise Rev::NotFoundError
  end

  after do
    VCR.eject_cassette
  end
end
