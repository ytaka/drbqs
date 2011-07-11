require 'thread'
require 'drb'
require 'drb/acl'
require 'rinda/tuplespace'
require 'rinda/rinda'
require 'logger'
require 'fileutils'

require 'filename'

require 'drbqs/server_define'

module DRbQS
  autoload :Server, 'drbqs/server'
  autoload :Client, 'drbqs/node/client'
  autoload :Task, 'drbqs/task'
  autoload :TaskGenerator, 'drbqs/task_generator'
  autoload :Manage, 'drbqs/manage'
  autoload :Config, 'drbqs/config'
  autoload :CommandTask, 'drbqs/task'
  autoload :CommandExecute, 'drbqs/task'
  autoload :TaskSet, 'drbqs/task'
  autoload :Utils, 'drbqs/utils'
  autoload :ExecuteNode, 'drbqs/execute_node'

  module SSH
    autoload :Shell, 'drbqs/ssh/shell'
    autoload :Host, 'drbqs/ssh/host'
  end

  autoload :FileTransfer, 'drbqs/transfer/file_transfer'
  autoload :TransferClient, 'drbqs/transfer/transfer_client'

  ROOT_DEFAULT_PORT = 13500

  VERSION = '0.0.13'
end
