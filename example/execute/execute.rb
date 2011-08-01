#!/usr/bin/env drbqs-execute
# -*-ruby-*-

usage message: "Message of this file", server: File.join(File.dirname(__FILE__), 'server.rb'), log: "/tmp/drbqs/log"

default server: :server1, port: 12345, node: [:node1, :node3, :node5]

ssh_directory = "/ssh/path/to"

server :server1, 'example.com' do |server, ssh|
  ssh.directory ssh_directory
  ssh.output "/path/to/log"
  ssh.nice 5
  server.load "server.rb"
  server.log_level 'error'
end

server :local, 'localhost' do |server|
  server.load "server.rb"
  server.log_level 'error'
end

node :node_base, template: true do |node, ssh|
  ssh.directory ssh_directory
  ssh.output "/path/to/node_ssh"
  ssh.nice 10
  node.process 2
  node.load "server.rb"
  node.log_level 'error'
end

ssh_user = 'user_name'
[1, 2, 3, 4, 5, 6].each do |n|
  name = "node%02d" % n
  node name, load: :node_base do |node, ssh|
    ssh.connect "#{ssh_user}@#{name}.example.com"
  end
end

node :even, group: [:node02, :node04, :node06]
node :odd, group: [:node01, :node03, :node05]
