# 
# Usage:
#  drbqs-server server_def.rb
# 

require_relative 'file.rb'

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  tgen = DRbQS::TaskGenerator.new(:sleep_time => 2)
  tgen.set do
    create_add_task(CreateFile.new(1), :create)
    create_add_task(CreateFile.new(2), :create_compress)
    create_add_task(CreateDirectory.new(3), :create)
    create_add_task(CreateDirectory.new(4), :create_compress)
  end
  server.add_task_generator(tgen)

  server.set_file_transfer(ENV['USER'], 'localhost', '/tmp/drbqs_transfer_test/')
end
