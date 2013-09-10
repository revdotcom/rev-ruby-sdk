require 'rake/testtask'
require 'yard'
require 'rubygems/tasks'

Rake::TestTask.new do |t|
  t.test_files = FileList['spec/lib/rev/*_spec.rb']
  t.verbose = true
end

YARD::Rake::YardocTask.new 

Gem::Tasks.new

task :default => :test