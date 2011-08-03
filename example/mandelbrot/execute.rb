DIR = File.dirname(__FILE__)

server :local_server, "localhost" do |srv|
  srv.load File.join(DIR, 'server.rb')
end

node :local_node do |nd|
  nd.load File.join(DIR, 'mandelbrot.rb')
  nd.process 2 # For dual core CPU
end
