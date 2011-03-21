require 'thread'
require 'logger'
require 'drb'
require 'drb/acl'
require 'rinda/tuplespace'
require 'rinda/rinda'

require 'drbqs/server_define'

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
  autoload :FileName, 'drbqs/utils/filename'

  ROOT_DEFAULT_PORT = 13500
end
