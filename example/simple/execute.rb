DIR = File.dirname(__FILE__)

default :port => 12345

server :local, "localhost" do |srv|
  srv.load File.join(DIR, 'server.rb')
end

node :local do |nd|
  nd.load File.join(DIR, 'task.rb')
end
