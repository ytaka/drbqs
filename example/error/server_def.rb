require_relative 'error.rb'

DRbQS.define_server(:check_alive => 300) do |server, argv, opts|
  server.queue.add(DRbQS::Task.new(TaskError, :exec))
  server.add_hook(:finish) do |serv|
    serv.exit
  end
end
