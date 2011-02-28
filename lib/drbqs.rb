require 'thread'
require 'logger'
require 'fileutils'
require 'drb'
require 'drb/acl'
require 'rinda/tuplespace'
require 'rinda/rinda'

module DRbQS
  autoload :Server, 'drbqs/server'
  autoload :Client, 'drbqs/client'

  ROOT_DEFAULT_PORT = 13500
end
