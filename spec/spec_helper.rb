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
  c.default_cassette_options = { :record => :once, :allow_unused_http_interactions => false, :match_requests_on => [:method, :uri, :headers] }
  c.hook_into :webmock
  c.ignore_hosts 'www.example.com' # used to stub requests manually, see http_client_spec
end
