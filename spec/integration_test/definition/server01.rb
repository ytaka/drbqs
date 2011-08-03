require_relative 'task_obj_definition.rb'

DRbQS.option_parser do |opt, hash|
  hash[:step] = 1
  opt.on('--step NUM', Integer, 'Set the step size.') do |v|
    hash[:step] = v
  end
end

DRbQS.define_server do |server, argv, opts|
  step = opts[:step]
  server.task_generator(:generate => 2) do |reg|
    1.step(100, 50) do |i|
      reg.create_add(TestSum.new, :calc, args: [i, i + 10, step]) do |srv, result|
        puts result
      end
    end
  end
end
