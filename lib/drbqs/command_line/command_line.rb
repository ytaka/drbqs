require 'drbqs'
require 'drbqs/manage/manage'
require 'drbqs/manage/execute_node'
require 'drbqs/command_line/argument'
require 'drbqs/command_line/command_base'
require 'optparse'

Version = DRbQS::VERSION

module DRbQS
  class Command
    autoload :Manage, 'drbqs/command_line/command_manage'
    autoload :Server, 'drbqs/command_line/command_server'
    autoload :Node, 'drbqs/command_line/command_node'
    autoload :SSH, 'drbqs/command_line/command_ssh'
    autoload :Execute, 'drbqs/command_line/command_execute'
  end
end
