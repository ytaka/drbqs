default :server => :server_local, :port => 13789, :node => [:node_odd, :node_even], :log => '/tmp/drbqs_execute'

current_dir = File.expand_path(File.dirname(__FILE__))

usage :message => <<MES, :server => File.join(current_dir, 'server.rb')
Calculate sum of numbers.
Results are output to logs in /tmp/drbqs_execute
MES

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
