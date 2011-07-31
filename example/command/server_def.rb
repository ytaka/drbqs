# 
# Usage:
#  drbqs-server server_def.rb
# 

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  tgen = DRbQS::Task::Generator.new(:sleep_time => 2)
  tgen.set do
    3.times do |i|
      add_task(DRbQS::CommandTask.new(["sleep #{@sleep_time}", 'echo hello world']))
    end
  end
  server.add_task_generator(tgen)
end
