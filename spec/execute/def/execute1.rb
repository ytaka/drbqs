# Use in process_define_spec.rb

register_server 'server_local', 'localhost' do |server|
  server.load 'server.rb'
end

register_server 'server_ssh', 'example.com' do |server, ssh|
  ssh.connect "example.com"
  server.load 'server.rb'
end

register_node 'node_local' do |node|
  node.log_level = Logger::DEBUG
end

register_node 'node_ssh' do |node, ssh|
  ssh.connect "example.com"
  node.log_level = Logger::DEBUG
end
