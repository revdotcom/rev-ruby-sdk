require_relative '../lib/rev-api'

#dependencies
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'
require 'turn'

module MiniTest
  class Spec
    class << self
      def xit(desc='anonymous')
        it(name) { skip 'DISABLED' }
      end
    end
  end
end

Turn.config do |c|
  c.format = :outline
  c.trace = false
  c.natural = true
end


VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/api_cassettes'
  c.default_cassette_options = { :record => :once, :allow_unused_http_interactions => false,
    :match_requests_on => [:method, :uri, :rev_headers] }
  c.hook_into :webmock
  c.ignore_hosts 'www.example.com' # used to stub requests manually, see http_client_spec

  # http://ruby-doc.org/stdlib-2.0.0/libdoc/net/http/rdoc/Net/HTTP.html#label-Compression - we ignore 'Accept-Encoding'
  c.register_request_matcher :rev_headers do |actual_request, expected_request|
    actual_request.headers.delete 'Accept-Encoding'

    # ignore specific version of a client recorded
    actual_user_agent = actual_request.headers['User-Agent'].to_s.split('/').first
    expected_user_agent = actual_request.headers['User-Agent'].to_s.split('/').first

    actual_request.headers.delete 'User-Agent'
    expected_request.headers.delete 'User-Agent'

    actual_request.headers == expected_request.headers# && actual_user_agent == expected_user_agent
  end

def create_input(options = {})
  [Rev::Input.new(options)]
end

end
