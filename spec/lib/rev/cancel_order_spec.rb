require_relative '../../spec_helper'

describe 'POST /orders/{order_num}/cancel' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  it 'must cancel order' do
    VCR.insert_cassette 'cancel_order'

    client.cancel_order('TC0166192942').must_equal true

    assert_requested :post, /.*\/api\/v1\/orders\/TC0166192942\/cancel/, :times => 1,
      :body => { :order_num => 'TC0166192942' }
  end

  it 'must raise ForbiddenError when cancellation is not allowed' do
    VCR.insert_cassette 'cancel_order_not_allowed'

    action = lambda { client.cancel_order('TC0367111289') }
    action.must_raise Rev::ForbiddenError
  end

  after do
    VCR.eject_cassette
  end
end