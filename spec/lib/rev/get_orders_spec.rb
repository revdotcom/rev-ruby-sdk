require_relative '../../spec_helper'

describe 'GET /orders' do
  let(:client) { Rev.new('welcome', 'AAAAAu/YjZ3phXU5FsF35yIcgiA=', 'www.revtrunk.com') }

  describe 'GET /orders without page number' do
    it 'must get first page of existing orders' do
      VCR.insert_cassette 'get_orders'

      page = client.get_orders_page

      assert_requested :get, /.*\/api\/v1\/orders\?page=0/, :times => 1

      page.orders.must_be_instance_of Array
      page.results_per_page.must_equal 8
      page.orders.size.must_equal 8
      page.page.must_equal 0
      page.total_count.must_equal 77
    end
  end

  describe 'GET /orders?page={pagenum}' do
    it 'must load any page' do
      VCR.insert_cassette 'get_third_page_of_orders'

      page = client.get_orders_page(2)

      assert_requested :get, /.*\/api\/v1\/orders\?page=2/, :times => 1

      page.orders.size.must_equal 8
      page.page.must_equal 2
      page.orders.first.order_number.must_equal 'TC0229215557'
    end
  end

  after do
    VCR.eject_cassette
  end
end