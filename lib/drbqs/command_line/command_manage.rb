module DRbQS
  class Command
    class Manage < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
  Manage DRbQS server by sending messages.
  <command> is 'signal', 'status', 'process', or 'initialize'.

  #{@@command_name} signal <uri> server-exit
  #{@@command_name} signal <uri> node-exit-after-task <node_number>
  #{@@command_name} signal <uri> node-wake <node_number>
  #{@@command_name} signal <uri> node-sleep <node_number>
  #{@@command_name} status <uri>
  #{@@command_name} history <uri>
  #{@@command_name} process list
  #{@@command_name} process clear
  #{@@command_name} send string <uri> <string>
  #{@@command_name} send file <uri> <path>
  #{@@command_name} initialize

HELP

      def initialize
        super(DRbQS::Setting::Manage)
      end

      def parse_option(argv)
        argv = option_parser_base(argv, HELP_MESSAGE, :debug => true) do |opt|
        end
        @setting.set_argument(*argv)
      end
    end
  end
end
