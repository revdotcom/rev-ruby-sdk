require 'date'
require File.dirname(__FILE__) + '/lib/rev-api/version'

Gem::Specification.new do |s|
  s.name        = 'rev-api'
  s.version     = Rev::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
  s.date        = Date.today.to_s
  s.summary     = "Ruby wrapper for Rev.com API"
  s.description = "Communicate with Rev.com API using plain Ruby objects without bothering about HTTP"
  s.authors     = ["Rev.com, Inc"]
  s.email       = 'api@rev.com'
  s.homepage    = 'http://www.rev.com/api'
  s.license     = 'Apache License 2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = [ "lib", "spec" ]

  s.add_runtime_dependency('httparty', '~> 0.11', '>= 0.11.0')

  s.add_development_dependency('webmock', '~> 1.11', '~> 1.11.0')
  s.add_development_dependency('vcr', '~> 2.6', '~> 2.6.0')
  s.add_development_dependency('turn', '~> 0.9', '~> 0.9.6')
  s.add_development_dependency('rake', '~> 10.1', '>= 10.1.0')
  s.add_development_dependency('yard', '~> 0')
  s.add_development_dependency('redcarpet', '~> 0')
  s.add_development_dependency('rubygems-tasks', '~> 0')

  s.has_rdoc = 'yard'
end
