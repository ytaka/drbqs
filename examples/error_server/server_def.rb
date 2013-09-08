require_relative 'error.rb'

DRbQS.define_server(:check_alive => 300) do |server, argv, opts|
  server.queue.add(DRbQS::Task.new(TaskTrue.new, :exec))
  sleep(1)
  raise "Error in definition of server."
end
