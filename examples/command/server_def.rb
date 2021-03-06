# 
# Usage:
#  drbqs-server server_def.rb
# 

DRbQS.define_server do |server, argv, opts|
  sleep_time = 2
  server.task_generator do |reg|
    3.times do |i|
      reg.add(DRbQS::CommandTask.new("sleep #{sleep_time}", "echo 'hello world (#{i})'"))
    end
  end
end
