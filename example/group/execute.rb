default :server => :server_local, :port => 13789, :log => '/tmp/drbqs_execute'

current_dir = File.expand_path(File.dirname(__FILE__))

usage :message => "Calculate sum of numbers", :server => File.join(current_dir, 'server.rb')

server :server, "localhost" do |server|
  server.load File.expand_path(File.join(File.dirname(__FILE__), 'server.rb'))
end

node :node_odd do |node|
  node.load File.join(current_dir, 'sum.rb')
  node.group :odd
end

node :node_even do |node|
  node.load File.join(current_dir, 'sum.rb')
  node.group :even
end
