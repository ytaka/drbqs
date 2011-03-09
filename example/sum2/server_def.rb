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

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  tgen = DRbQS::TaskGenerator.new(:start_num => (argv[0] || 10).to_i,
                                  :end_num => (argv[1] || 100).to_i,
                                  :step_num => opts[:step] || 10)
  tgen.set do
    @start_num.step(@end_num, @step_num) do |i|
      create_add_task(Sum.new(i - 10, i), :exec) do |srv, ret|
        puts "Receive: #{ret.inspect}"
      end
    end
  end
  server.add_task_generator(tgen)
end
