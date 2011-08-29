server = DRbQS::Server.new(:port => 13501)
server.task_generator do |tgen|
  tgen.set do
    5.times do |i|
      create_add(i, :to_s)
    end
  end
end
server.set_initialization_task(DRbQS::Task.new(Kernel, :puts, ['hook: initialize']))
server.set_finalization_task(DRbQS::Task.new(Kernel, :puts, ['hook: finalize']))
server.set_signal_trap
server.start
server.wait
