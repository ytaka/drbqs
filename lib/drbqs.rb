require 'thread'
require 'drb'
require 'drb/acl'
require 'rinda/tuplespace'
require 'rinda/rinda'

require 'drbqs/server_define'

autoload :Logger, 'logger'
autoload :FileUtils, 'fileutils'

gem 'filename'
autoload :FileName, 'filename'

gem 'net-sftp'
module Net
  autoload :SFTP, 'net/sftp'
end

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

  autoload :FileTransfer, 'drbqs/transfer/transfer'

  module Transfer
    autoload :SFTP, 'drbqs/transfer/transfer'
    autoload :Local, 'drbqs/transfer/transfer'
  end

  ROOT_DEFAULT_PORT = 13500

  VERSION = '0.0.13'
end
