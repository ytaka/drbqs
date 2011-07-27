require 'drbqs/command_line/argument'
require 'drbqs/setting/data_container'
require 'drbqs/setting/source'
require 'drbqs/setting/base'

module DRbQS
  class Setting
    autoload :Server, 'drbqs/setting/server'
    autoload :Node, 'drbqs/setting/node'
    autoload :Manage, 'drbqs/setting/manage'
    autoload :SSH, 'drbqs/setting/ssh'
    autoload :Execute, 'drbqs/setting/execute'
  end
end
