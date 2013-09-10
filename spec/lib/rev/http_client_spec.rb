require_relative '../../spec_helper'

describe Rev::HttpClient do
  it 'must support predefined production host' do
    client = Rev::HttpClient.new('foo', 'bar', Rev::Api::PRODUCTION_HOST)
    Rev::HttpClient.base_uri.must_equal 'https://www.rev.com/api/v1'
  end

  it 'must support predefined sandbox host' do
    client = Rev::HttpClient.new('foo', 'bar', Rev::Api::SANDBOX_HOST)
    Rev::HttpClient.base_uri.must_equal 'https://api-sandbox.rev.com/api/v1'
  end

  it 'must support custom host for development purposes' do
    client = Rev::HttpClient.new('foo', 'bar', 'localhost')
    Rev::HttpClient.base_uri.must_equal 'https://localhost/api/v1'
  end

  it 'must include authorization and User-Agent headers for any request' do
    host = 'www.example.com'
    stub_request(:any, host)

    client = Rev::HttpClient.new('foo', 'bar', host)
    client.get('/orders')

    assert_requested :get, "https://#{host}/api/v1/orders", :headers => {
      'Authorization' => "Rev foo:bar",
      'User-Agent' => Rev::HttpClient::USER_AGENT
    }
  end
end

