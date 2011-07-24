require 'drbqs'
require 'drbqs/manage/manage'
require 'drbqs/manage/execute_node'
require 'drbqs/utility/command_line/argument'
require 'drbqs/utility/command_line/command_base'
require 'optparse'

Version = DRbQS::VERSION

module DRbQS
  class Command
    autoload :Manage, 'drbqs/utility/command_line/command_manage'
    autoload :Server, 'drbqs/utility/command_line/command_server'
    autoload :Node, 'drbqs/utility/command_line/command_node'
    autoload :SSH, 'drbqs/utility/command_line/command_ssh'
  end
end
