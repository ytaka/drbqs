require 'thread'
require 'logger'
require 'fileutils'
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

  ROOT_DEFAULT_PORT = 13500
end
