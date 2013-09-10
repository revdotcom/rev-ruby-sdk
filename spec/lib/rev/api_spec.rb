require_relative '../../spec_helper'

describe 'API Client' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  it 'must raise NotAuthorizedError on unauthorized HTTP response' do
    VCR.insert_cassette 'unauthorized'

    unauthorized_client = Rev.new('welcome', 'trololo', Rev::Api::SANDBOX_HOST)
    action = lambda { unauthorized_client.get_orders_page }
    action.must_raise Rev::NotAuthorizedError
  end

  it 'must raise NotFoundError on NotFound HTTP response' do
    VCR.insert_cassette 'not_found_order'

    action = lambda { client.get_order('trololo') }
    action.must_raise Rev::NotFoundError
  end

  after do
    VCR.eject_cassette
  end
end
