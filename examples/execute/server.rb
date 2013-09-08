require_relative 'sum.rb'

DRbQS.option_parser do |opt, hash|
  opt.on('--step NUM', Integer) do |v|
    hash[:step] = v
  end
end

output_path = File.expand_path(File.join(File.dirname(__FILE__), "../../example_execute.log"))

DRbQS.define_server(:check_alive => 5) do |server, argv, opts|
  start_num = (argv[0] || 10).to_i
  end_num = (argv[1] || 50).to_i
  step_num = opts[:step] || 10
  start_num.step(end_num, step_num) do |i|
    task = DRbQS::Task.new(Sum.new(i - 10, i), :exec, :args => [], :note => "#{i-10} to #{i}") do |srv, ret|
      open(output_path, "a+") do |f|
        f.puts "Receive: #{ret.inspect}"
      end
    end
    server.queue.add(task)
  end

  server.add_hook(:finish) do |serv|
    serv.exit
  end
end
