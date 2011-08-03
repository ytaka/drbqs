require_relative 'task.rb'

DRbQS.option_parser("Usage of server") do |prs, opts|
  prs.on('-s STR', '--string STR', String, "Set string.") do |v|
    opts[:string] = v
  end
  prs.on('-n NUM', '--number NUM', Integer, "Set number.") do |v|
    opts[:number] = v
  end
end

DRbQS.define_server(finish_exit: true) do |server, argv, opts|
  
end
