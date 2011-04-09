require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "drbqs"
  gem.homepage = "http://github.com/ytaka/drbqs"
  gem.license = "GPL3"
  gem.summary = "dRuby Queueing System"
  gem.description = "Task queuing system over network that is implemented by dRuby."
  gem.email = "d@ytak.info"
  gem.authors = ["Takayuki YAMAGUCHI"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'net-ssh', '>= 2.1.3'
  gem.add_runtime_dependency 'net-ssh-shell', '>= 0.1.0'
  gem.add_runtime_dependency 'filename', '>= 0.0.5'
  gem.add_development_dependency 'rspec', '>= 2.5.0'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
