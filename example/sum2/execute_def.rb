default :server => :server_local, :port => 13789, :log => '/tmp/drbqs_execute'

usage :message => "Calculate sum of numbers", :server => File.join(File.dirname(__FILE__), 'server_def.rb')

register_server :server_template, :template => true do |server, ssh|
  server.load 'server_def.rb'
end

register_server :server_local, "localhost" do |server|
  server.load File.expand_path(File.join(File.dirname(__FILE__), 'server_def.rb'))
end

ssh_localhost = "#{ENV['USER']}@localhost"
current_dir = File.expand_path(File.dirname(__FILE__))

register_server :server_ssh, "localhost" do |server, ssh|
  ssh.connect ssh_localhost
  ssh.directory current_dir
  ssh.output "/tmp/drbqs_ssh/server"
  server.load 'server_def.rb'
end

register_node :node_template, template: true do |node|
  node.load 'sum.rb'
end

register_node :node_local do |node|
  node.load File.expand_path(File.join(File.dirname(__FILE__), 'sum.rb'))
  node.process 2
end

register_node :node_ssh do |node, ssh|
  ssh.connect ssh_localhost
  ssh.directory current_dir
  ssh.output "/tmp/drbqs_ssh/node"
  node.load 'sum.rb'
  node.process 2
end

register_node :node_group, :group => [:node_local, :node_ssh]
