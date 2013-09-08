# 
# Usage:
#  * Start only server
#  drbqs-server server_def.rb -- 30 50
#  drbqs-server server_def.rb -- 100 500 --step 100
# 
#  * Start server with 2 nodes
#  drbqs-server examples/sum/server_def.rb --execute-node 2
# 

require_relative 'sum.rb'

DRbQS.option_parser do |opt, hash|
  opt.on('--step NUM', Integer) do |v|
    hash[:step] = v
  end
end

DRbQS.define_server(:check_alive => 5) do |server, argv, opts|
  start_num = (argv[0] || 10).to_i
  end_num = (argv[1] || 50).to_i
  step_num = opts[:step] || 10
  start_num.step(end_num, step_num) do |i|
    task = DRbQS::Task.new(Sum.new(i - 10, i), :exec, :note => "#{i-10} to #{i}") do |srv, ret|
      puts "Receive: #{ret.inspect}"
    end
    server.queue.add(task)
  end

  server.add_hook(:finish) do |serv|
    serv.exit
  end
end
