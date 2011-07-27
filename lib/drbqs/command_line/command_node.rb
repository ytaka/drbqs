module DRbQS
  class Command
    class Node < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <uri> [options ...]
  Start DRbQS nodes connecting to <uri>.

HELP

      def initialize
        super(DRbQS::Setting::Node)
      end

      def parse_option(argv)
        argv = option_parser_base(argv, HELP_MESSAGE, :log_level => true, :daemon => true, :debug => true) do |opt|
          opt.on('-l', '--load FILE', String, 'Add a file to load.') do |v|
            @setting.set(:load, v)
          end
          opt.on('-P', '--process NUM', Integer, 'Set the number of node processes to execute.') do |v|
            @setting.set(:process, v)
          end
          opt.on('--loadavg STR', String, 'Set the threshold load average to sleep.') do |v|
            @setting.set(:loadavg, v)
          end
          opt.on('--log-prefix STR', String, "Set the prefix of log files. The default is '#{@setting.default[:log_prefix][0]}'.") do |v|
            @setting.set(:log_prefix, v)
          end
          opt.on('--log-stdout', 'Use stdout for outputting logs. This option cancels --log-prefix.') do |v|
            @setting.set(:log_stdout)
          end
        end
        @setting.set_argument(*argv)
      end
    end
  end
end
