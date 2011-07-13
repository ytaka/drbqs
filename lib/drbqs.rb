require 'thread'
require 'drb'
require 'drb/acl'
require 'rinda/tuplespace'
require 'rinda/rinda'
require 'logger'
require 'fileutils'

require 'filename'

require 'drbqs/server_define'
require 'drbqs/utility/utils'

module DRbQS
  autoload :Server, 'drbqs/server/server'
  autoload :Client, 'drbqs/node/client'
  autoload :Config, 'drbqs/config/config'

  ROOT_DEFAULT_PORT = 13500

  VERSION = '0.0.13'
end
