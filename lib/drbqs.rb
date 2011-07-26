require 'thread'
require 'drb'
require 'drb/acl'
require 'socket'
require 'rinda/tuplespace'
require 'rinda/rinda'
require 'logger'
require 'fileutils'

require 'filename'

require 'drbqs/execute/server_define'
require 'drbqs/utility/misc'

module DRbQS
  autoload :Server, 'drbqs/server/server'
  autoload :Node, 'drbqs/node/node'
  autoload :Config, 'drbqs/config/config'
  autoload :Setting, 'drbqs/setting/setting'

  ROOT_DEFAULT_PORT = 13500

  VERSION = '0.0.14'
end
