register_server('server_local') do |srv|
  srv.argument << 'server.rb'
end

register_node('node_local') do |node|
  node.log_level = Logger::DEBUG
end
