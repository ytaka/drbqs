default :server => :server_local, :port => 13789, :log => '/tmp/drbqs_execute'

register_server :server_local, "localhost" do |server|
  server.load File.expand_path(File.join(File.dirname(__FILE__), 'server_def.rb'))
end

register_server :server_ssh, "localhost" do |server, ssh|
  ssh.connect 'localhost'
  ssh.directory File.expand_path(File.dirname(__FILE__))
  ssh.output "/tmp/drbqs_ssh/server"
  server.load 'server_def.rb'
end

register_node :node_local do |node|
  node.load File.expand_path(File.join(File.dirname(__FILE__), 'sum.rb'))
  node.process 2
end

register_node :node_ssh do |node, ssh|
  ssh.connect 'localhost'
  ssh.directory File.expand_path(File.dirname(__FILE__))
  ssh.output "/tmp/drbqs_ssh/node"
  node.load 'sum.rb'
  node.process 2
end
