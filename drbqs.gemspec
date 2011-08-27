# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "drbqs/version"

Gem::Specification.new do |s|
  s.name        = "drbqs"
  s.version     = DRbQS::VERSION
  s.authors     = ["Takayuki YAMAGUCHI"]
  s.email       = ["d@ytak.info"]
  s.homepage    = ""
  s.summary     = "dRuby Queueing System"
  s.description = "Task queuing system over network that is implemented by dRuby."

  s.rubyforge_project = "drbqs"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec", ">= 2.6.0"
  s.add_development_dependency "yard", ">= 0.7.2"
  s.add_runtime_dependency 'filename', '>= 0.1.0'
  s.add_runtime_dependency "user_config", ">= 0.0.2"
  s.add_runtime_dependency 'net-ssh', '>= 2.1.0'
  s.add_runtime_dependency 'net-ssh-shell', '>= 0.2.0'
  s.add_runtime_dependency "net-sftp", ">= 2.0.5"
  s.add_runtime_dependency "sys-proctable"
end
