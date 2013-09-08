DIR = File.dirname(__FILE__)

current_dir = File.expand_path(File.dirname(__FILE__))

usage :message => <<MES, :server => File.join(current_dir, 'server.rb')
Calculate Mandelbrot set.
Result is output to the directory "result_mandelbrot".
MES

server :local_server, "localhost" do |srv|
  srv.load File.join(DIR, 'server.rb')
end

node :local_node do |nd|
  nd.load File.join(DIR, 'mandelbrot.rb')
  nd.process 2 # For dual core CPU
end
