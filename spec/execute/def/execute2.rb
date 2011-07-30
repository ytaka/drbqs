# Use in process_define_spec.rb

server_file = File.join(File.dirname(__FILE__), '../../integration_test/definition/server02.rb')
usage message: "Usage of this definition.", server: server_file

default log: '/tmp/drbqs_tmp_log', node: [:node_ssh]

server 'server_local', 'localhost' do |server|
  server.load server_file
end

server 'server_ssh', 'example.com' do |server, ssh|
  ssh.connect "example.com"
  server.load 'server.rb'
end

node 'node_local' do |node|
  node.log_level = Logger::DEBUG
end

node 'node_ssh' do |node, ssh|
  ssh.connect "example.com"
  node.log_level = Logger::DEBUG
end
