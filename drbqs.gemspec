# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{drbqs}
  s.version = "0.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Takayuki YAMAGUCHI"]
  s.date = %q{2011-03-20}
  s.description = %q{Task queuing system over network that is implemented by dRuby.}
  s.email = %q{d@ytak.info}
  s.executables = ["drbqs-manage", "drbqs-node", "drbqs-server"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/drbqs-manage",
    "bin/drbqs-node",
    "bin/drbqs-server",
    "drbqs.gemspec",
    "example/README.md",
    "example/command/server_def.rb",
    "example/drbqs-manage-test.rb",
    "example/drbqs-node-test.rb",
    "example/drbqs-server-test.rb",
    "example/server/server.rb",
    "example/sum/server_def.rb",
    "example/sum/sum.rb",
    "example/sum2/server_def.rb",
    "example/sum2/sum.rb",
    "lib/drbqs.rb",
    "lib/drbqs/acl_file.rb",
    "lib/drbqs/client.rb",
    "lib/drbqs/config.rb",
    "lib/drbqs/connection.rb",
    "lib/drbqs/manage.rb",
    "lib/drbqs/message.rb",
    "lib/drbqs/node_list.rb",
    "lib/drbqs/queue.rb",
    "lib/drbqs/server.rb",
    "lib/drbqs/server_define.rb",
    "lib/drbqs/server_hook.rb",
    "lib/drbqs/ssh_shell.rb",
    "lib/drbqs/task.rb",
    "lib/drbqs/task_client.rb",
    "lib/drbqs/task_generator.rb",
    "spec/acl_file_spec.rb",
    "spec/config_spec.rb",
    "spec/connection_spec.rb",
    "spec/data/acl.txt",
    "spec/manage_spec.rb",
    "spec/message_spec.rb",
    "spec/node_list_spec.rb",
    "spec/queue_spec.rb",
    "spec/server_define_spec.rb",
    "spec/server_hook_spec.rb",
    "spec/server_spec.rb",
    "spec/spec_helper.rb",
    "spec/ssh_shell_spec.rb",
    "spec/task_client_spec.rb",
    "spec/task_generator_spec.rb",
    "spec/task_spec.rb",
    "spec/test/test1.rb",
    "spec/test1_spec.rb",
    "spec/test2_spec.rb"
  ]
  s.homepage = %q{http://github.com/ytaka/drbqs}
  s.licenses = ["GPL3"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{dRuby Queueing System}
  s.test_files = [
    "spec/acl_file_spec.rb",
    "spec/config_spec.rb",
    "spec/connection_spec.rb",
    "spec/manage_spec.rb",
    "spec/message_spec.rb",
    "spec/node_list_spec.rb",
    "spec/queue_spec.rb",
    "spec/server_define_spec.rb",
    "spec/server_hook_spec.rb",
    "spec/server_spec.rb",
    "spec/spec_helper.rb",
    "spec/ssh_shell_spec.rb",
    "spec/task_client_spec.rb",
    "spec/task_generator_spec.rb",
    "spec/task_spec.rb",
    "spec/test/test1.rb",
    "spec/test1_spec.rb",
    "spec/test2_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 2.5.0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 2.5.0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

