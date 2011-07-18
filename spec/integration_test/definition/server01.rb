require_relative 'task_obj_definition.rb'

DRbQS.option_parser do |opt, hash|
  hash[:step] = 1
  opt.on('--step NUM', Integer, 'Set the step size.') do |v|
    hash[:step] = v
  end
end

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  tgen = DRbQS::TaskGenerator.new(:step => opts[:step])
  tgen.set(:generate => 2) do
    1.step(100, 50) do |i|
      create_add_task(TestSum.new, :calc, [i, i + 10, @step]) do |srv, result|
        puts result
      end
    end
  end
  server.add_task_generator(tgen)
end
