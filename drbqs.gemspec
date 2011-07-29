# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{drbqs}
  s.version = "0.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Takayuki YAMAGUCHI"]
  s.date = %q{2011-07-29}
  s.description = %q{Task queuing system over network that is implemented by dRuby.}
  s.email = %q{d@ytak.info}
  s.executables = ["drbqs-execute", "drbqs-manage", "drbqs-node", "drbqs-server", "drbqs-ssh"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/drbqs-execute",
    "bin/drbqs-manage",
    "bin/drbqs-node",
    "bin/drbqs-server",
    "bin/drbqs-ssh",
    "drbqs.gemspec",
    "example/README.md",
    "example/command/server_def.rb",
    "example/error_server/error.rb",
    "example/error_server/server_def.rb",
    "example/error_task/error.rb",
    "example/error_task/server_def.rb",
    "example/server/server.rb",
    "example/sum/server_def.rb",
    "example/sum/sum.rb",
    "example/sum2/execute_def.rb",
    "example/sum2/server_def.rb",
    "example/sum2/sum.rb",
    "example/transfer/file.rb",
    "example/transfer/server_def.rb",
    "lib/drbqs.rb",
    "lib/drbqs/command_line/argument.rb",
    "lib/drbqs/command_line/command_base.rb",
    "lib/drbqs/command_line/command_execute.rb",
    "lib/drbqs/command_line/command_line.rb",
    "lib/drbqs/command_line/command_manage.rb",
    "lib/drbqs/command_line/command_node.rb",
    "lib/drbqs/command_line/command_server.rb",
    "lib/drbqs/command_line/command_ssh.rb",
    "lib/drbqs/command_line/option_setting.rb",
    "lib/drbqs/config/config.rb",
    "lib/drbqs/config/process_list.rb",
    "lib/drbqs/config/ssh_host.rb",
    "lib/drbqs/execute/process_define.rb",
    "lib/drbqs/execute/register.rb",
    "lib/drbqs/execute/server_define.rb",
    "lib/drbqs/manage/execute_node.rb",
    "lib/drbqs/manage/manage.rb",
    "lib/drbqs/manage/send_signal.rb",
    "lib/drbqs/manage/ssh_execute.rb",
    "lib/drbqs/manage/ssh_shell.rb",
    "lib/drbqs/node/connection.rb",
    "lib/drbqs/node/node.rb",
    "lib/drbqs/node/state.rb",
    "lib/drbqs/node/task_client.rb",
    "lib/drbqs/server/acl_file.rb",
    "lib/drbqs/server/check_alive.rb",
    "lib/drbqs/server/history.rb",
    "lib/drbqs/server/message.rb",
    "lib/drbqs/server/node_list.rb",
    "lib/drbqs/server/prof.rb",
    "lib/drbqs/server/queue.rb",
    "lib/drbqs/server/server.rb",
    "lib/drbqs/server/server_hook.rb",
    "lib/drbqs/server/test/node.rb",
    "lib/drbqs/server/test/server.rb",
    "lib/drbqs/server/transfer_setting.rb",
    "lib/drbqs/setting/base.rb",
    "lib/drbqs/setting/data_container.rb",
    "lib/drbqs/setting/execute.rb",
    "lib/drbqs/setting/manage.rb",
    "lib/drbqs/setting/node.rb",
    "lib/drbqs/setting/server.rb",
    "lib/drbqs/setting/setting.rb",
    "lib/drbqs/setting/source.rb",
    "lib/drbqs/setting/ssh.rb",
    "lib/drbqs/task/command_task.rb",
    "lib/drbqs/task/task.rb",
    "lib/drbqs/task/task_generator.rb",
    "lib/drbqs/utility/misc.rb",
    "lib/drbqs/utility/temporary.rb",
    "lib/drbqs/utility/transfer/file_transfer.rb",
    "lib/drbqs/utility/transfer/transfer_client.rb",
    "spec/command_line/command_base_spec.rb",
    "spec/command_line/commands_spec.rb",
    "spec/command_line/option_setting_spec.rb",
    "spec/config/config_spec.rb",
    "spec/config/process_list_spec.rb",
    "spec/config/ssh_host_spec.rb",
    "spec/execute/def/execute1.rb",
    "spec/execute/def/no_def.rb",
    "spec/execute/process_define_spec.rb",
    "spec/execute/register_spec.rb",
    "spec/execute/server_define_spec.rb",
    "spec/integration_test/01_basic_usage_spec.rb",
    "spec/integration_test/02_use_generator_spec.rb",
    "spec/integration_test/03_use_temporary_file_spec.rb",
    "spec/integration_test/04_use_unix_domain_spec.rb",
    "spec/integration_test/05_server_exit_signal_spec.rb",
    "spec/integration_test/06_node_exit_after_task_spec.rb",
    "spec/integration_test/07_command_server_with_node_spec.rb",
    "spec/integration_test/08_shutdown_unused_nodes_spec.rb",
    "spec/integration_test/09_server_process_data_spec.rb",
    "spec/integration_test/10_test_server_spec.rb",
    "spec/integration_test/definition/server01.rb",
    "spec/integration_test/definition/server02.rb",
    "spec/integration_test/definition/task_obj_definition.rb",
    "spec/manage/manage_spec.rb",
    "spec/manage/send_signal_spec.rb",
    "spec/manage/ssh_shell_spec.rb",
    "spec/node/connection_spec.rb",
    "spec/node/state_spec.rb",
    "spec/node/task_client_spec.rb",
    "spec/server/acl_file_spec.rb",
    "spec/server/check_alive_spec.rb",
    "spec/server/data/acl.txt",
    "spec/server/history_spec.rb",
    "spec/server/message_spec.rb",
    "spec/server/node_list_spec.rb",
    "spec/server/queue_spec.rb",
    "spec/server/server_hook_spec.rb",
    "spec/server/server_spec.rb",
    "spec/server/transfer_setting_spec.rb",
    "spec/setting/base_spec.rb",
    "spec/setting/data_container_spec.rb",
    "spec/setting/execute_spec.rb",
    "spec/setting/manage_spec.rb",
    "spec/setting/node_spec.rb",
    "spec/setting/server_spec.rb",
    "spec/setting/source_spec.rb",
    "spec/spec_helper.rb",
    "spec/task/file_transfer_spec.rb",
    "spec/task/task_generator_spec.rb",
    "spec/task/task_spec.rb",
    "spec/utility/argument_spec.rb",
    "spec/utility/misc_spec.rb",
    "spec/utility/temporary_spec.rb"
  ]
  s.homepage = %q{http://github.com/ytaka/drbqs}
  s.licenses = ["GPL3"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{dRuby Queueing System}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 2.6.0"])
      s.add_development_dependency(%q<yard>, [">= 0.7.2"])
      s.add_development_dependency(%q<bundler>, [">= 1.0.15"])
      s.add_development_dependency(%q<jeweler>, [">= 1.6.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<filename>, [">= 0.1.0"])
      s.add_development_dependency(%q<user_config>, [">= 0.0.1"])
      s.add_development_dependency(%q<net-ssh>, [">= 2.1.4"])
      s.add_development_dependency(%q<net-ssh-shell>, [">= 0.2.0"])
      s.add_development_dependency(%q<net-sftp>, [">= 2.0.5"])
      s.add_development_dependency(%q<sys-proctable>, [">= 0"])
      s.add_runtime_dependency(%q<filename>, [">= 0.1.0"])
      s.add_runtime_dependency(%q<user_config>, [">= 0.0.2"])
      s.add_runtime_dependency(%q<net-ssh>, [">= 2.1.3"])
      s.add_runtime_dependency(%q<net-ssh-shell>, [">= 0.1.0"])
      s.add_runtime_dependency(%q<net-sftp>, [">= 2.0.5"])
      s.add_runtime_dependency(%q<sys-proctable>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 2.6.0"])
      s.add_dependency(%q<yard>, [">= 0.7.2"])
      s.add_dependency(%q<bundler>, [">= 1.0.15"])
      s.add_dependency(%q<jeweler>, [">= 1.6.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<filename>, [">= 0.1.0"])
      s.add_dependency(%q<user_config>, [">= 0.0.1"])
      s.add_dependency(%q<net-ssh>, [">= 2.1.4"])
      s.add_dependency(%q<net-ssh-shell>, [">= 0.2.0"])
      s.add_dependency(%q<net-sftp>, [">= 2.0.5"])
      s.add_dependency(%q<sys-proctable>, [">= 0"])
      s.add_dependency(%q<filename>, [">= 0.1.0"])
      s.add_dependency(%q<user_config>, [">= 0.0.2"])
      s.add_dependency(%q<net-ssh>, [">= 2.1.3"])
      s.add_dependency(%q<net-ssh-shell>, [">= 0.1.0"])
      s.add_dependency(%q<net-sftp>, [">= 2.0.5"])
      s.add_dependency(%q<sys-proctable>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 2.6.0"])
    s.add_dependency(%q<yard>, [">= 0.7.2"])
    s.add_dependency(%q<bundler>, [">= 1.0.15"])
    s.add_dependency(%q<jeweler>, [">= 1.6.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<filename>, [">= 0.1.0"])
    s.add_dependency(%q<user_config>, [">= 0.0.1"])
    s.add_dependency(%q<net-ssh>, [">= 2.1.4"])
    s.add_dependency(%q<net-ssh-shell>, [">= 0.2.0"])
    s.add_dependency(%q<net-sftp>, [">= 2.0.5"])
    s.add_dependency(%q<sys-proctable>, [">= 0"])
    s.add_dependency(%q<filename>, [">= 0.1.0"])
    s.add_dependency(%q<user_config>, [">= 0.0.2"])
    s.add_dependency(%q<net-ssh>, [">= 2.1.3"])
    s.add_dependency(%q<net-ssh-shell>, [">= 0.1.0"])
    s.add_dependency(%q<net-sftp>, [">= 2.0.5"])
    s.add_dependency(%q<sys-proctable>, [">= 0"])
  end
end

