task_generator = DRbQS::Task::Generator.new(:iterate => 3)
task_generator.set do
  5.times do |i|
    create_add_task(i, :to_s)
  end
end

server = DRbQS::Server.new(:port => 13501, :finish_exit => true)
server.add_task_generator(task_generator)
server.set_initialization_task(DRbQS::Task.new(Kernel, :puts, ['hook: initialize']))
server.set_finalization_task(DRbQS::Task.new(Kernel, :puts, ['hook: finalize']))
server.set_signal_trap
server.start
server.wait
