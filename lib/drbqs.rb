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
end
