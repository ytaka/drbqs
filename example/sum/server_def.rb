require_relative 'sum.rb'

DRbQS.define_server do |server|
  10.step(100, 10) do |i|
    task = DRbQS::Task.new(Sum.new(i - 10, i), :exec)
    server.queue.add(task)
  end

  server.set_finish_hook do |serv|
    serv.exit
  end
end
