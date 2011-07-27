module DRbQS
  class Command
    class Node < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <uri> [options ...]
  Start DRbQS nodes connecting to <uri>.

HELP

      def initialize
        super(DRbQS::Setting::Node, HELP_MESSAGE)
      end

      def parse_option(argv)
        argv = option_parser_base(argv, :log_level => true, :daemon => true, :debug => true) do
          set(:load, '-l', '--load FILE', String, 'Add a file to load.')
          set(:process, '-P', '--process NUM', Integer, 'Set the number of node processes to execute.')
          set(:loadavg, '--loadavg STR', String, 'Set the threshold load average to sleep.')
          set(:log_prefix, '--log-prefix STR', String, "Set the prefix of log files. The default is '#{setting.default[:log_prefix][0]}'.")
          set(:log_stdout, '--log-stdout', 'Use stdout for outputting logs. This option cancels --log-prefix.')
        end
        setting.set_argument(*argv)
      end
    end
  end
end
