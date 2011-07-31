require_relative 'task_obj_definition.rb'

DRbQS.option_parser do |opt, hash|
  hash[:step] = 1
  opt.on('--step NUM', Integer, 'Set the step size.') do |v|
    hash[:step] = v
  end
end

DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
  tgen = DRbQS::Task::Generator.new(:step => opts[:step])
  tgen.set(:generate => 2) do
    raise "Error raise"
  end
  server.add_task_generator(tgen)
end
