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
  autoload :Client, 'drbqs/client'
  autoload :Task, 'drbqs/task'
  autoload :TaskGenerator, 'drbqs/task_generator'
  autoload :Manage, 'drbqs/manage'
  autoload :Config, 'drbqs/config'
  autoload :SSHShell, 'drbqs/ssh/shell'
  autoload :SSHHost, 'drbqs/ssh/host'
  autoload :CommandTask, 'drbqs/task'
  autoload :CommandExecute, 'drbqs/task'
  autoload :TaskSet, 'drbqs/task'
  autoload :Transfer, 'drbqs/ssh/transfer'
  autoload :FileTransfer, 'drbqs/ssh/transfer'
  autoload :Utils, 'drbqs/utils'
  autoload :ExecuteNode, 'drbqs/execute_node'

  ROOT_DEFAULT_PORT = 13500

  VERSION = '0.0.13'
end
