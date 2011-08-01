require_relative 'task.rb'

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  task = DRbQS::Task.new(Sum.new(10, 20, 2), :calc) do |srv, result|
    puts "Result is #{result}"
  end
  server.queue.add(task)
end
