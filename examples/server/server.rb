# 
# Start server:
# drbqs-server examples/server/server.rb
# Start node:
# drbqs-node bin/drbqs-node druby://:13501
# Stop server:
# drbqs-manage signal druby://:13501 server-exit
# 

server = DRbQS::Server.new(:port => 13501)
server.task_generator do |reg|
  5.times do |i|
    reg.create_add(i, :to_s)
  end
end
server.set_initialization_task(DRbQS::Task.new(Kernel, :puts, :args => ['hook: initialize']))
server.set_finalization_task(DRbQS::Task.new(Kernel, :puts, :args => ['hook: finalize']))
server.set_signal_trap
server.start
server.wait
