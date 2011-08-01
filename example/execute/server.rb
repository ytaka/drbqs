DRbQS.option_parser do |prs, opts|
  prs.on('-a STR', String, "Set the value of a.") do |v|
  end
  prs.on('-b NUM', Integer, "Set the value of b.") do |v|
  end
end

DRbQS.define_server do |server, argv, opts|

end
