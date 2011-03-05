# 
# Usage:
#  drbqs-server server_def.rb -- 30 50
#  drbqs-server server_def.rb -- 100 500 --step 100
# 

require_relative 'sum.rb'

DRbQS.option_parser do |opt, hash|
  opt.on('--step NUM', Integer) do |v|
    hash[:step] = v
  end
end

DRbQS.define_server do |server, argv, opts|
  start_num = (argv[0] || 10).to_i
  end_num = (argv[1] || 100).to_i
  step_num = opts[:step] || 10
  start_num.step(end_num, step_num) do |i|
    task = DRbQS::Task.new(Sum.new(i - 10, i), :exec)
    server.queue.add(task)
  end

  server.set_finish_hook do |serv|
    serv.exit
  end
end
