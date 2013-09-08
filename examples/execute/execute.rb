#!/usr/bin/env drbqs-execute

usage message: "Message of this file", server: File.join(File.dirname(__FILE__), 'server.rb')

default server: :server, log: "/tmp/drbqs_log"

server :server do |server|
  server.load File.join(File.dirname(__FILE__), "server.rb")
  server.log_level "debug"
end
