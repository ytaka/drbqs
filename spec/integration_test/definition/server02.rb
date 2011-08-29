require_relative 'task_obj_definition.rb'

DRbQS.option_parser do |opt, hash|
  hash[:step] = 1
  opt.on('--step NUM', Integer, 'Set the step size.') do |v|
    hash[:step] = v
  end
end

DRbQS.define_server do |server, argv, opts|
  server.task_generator do |tgen|
    tgen.set(:generate => 2) do
      raise "Error raise"
    end
  end
end
