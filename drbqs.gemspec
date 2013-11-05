# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "drbqs/version"

Gem::Specification.new do |spec|
  spec.name        = "drbqs"
  spec.version     = DRbQS::VERSION
  spec.authors     = ["Takayuki YAMAGUCHI"]
  spec.email       = ["d@ytak.info"]
  spec.homepage    = ""
  spec.summary     = "dRuby Queueing System"
  spec.description = "Task queuing system over network that is implemented by dRuby."
  spec.license = "GPLv3"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # specify any dependencies here; for example:
  spec.add_development_dependency "rspec", ">= 2.14.1"
  spec.add_development_dependency "yard", ">= 0.7.2"
  spec.add_runtime_dependency 'filename', '>= 0.1.0'
  spec.add_runtime_dependency "user_config", ">= 0.0.2"
  spec.add_runtime_dependency 'net-ssh', '>= 2.1.0'
  spec.add_runtime_dependency 'net-ssh-shell', '>= 0.2.0'
  spec.add_runtime_dependency "net-sftp", ">= 2.0.5"
  spec.add_runtime_dependency "sys-proctable"
  spec.add_runtime_dependency "activesupport"
end
