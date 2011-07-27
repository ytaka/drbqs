module DRbQS
  class Command
    class Execute < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition> [arguments ...]
  Execute DRbQS server and some nodes from definition file.

HELP

      def initialize
        super(DRbQS::Setting::Execute, HELP_MESSAGE)
      end

      def parse_option(argv)
        args = option_parser_base(argv) do
          set(:port, '--port NUM', Integer, 'Set the port number.')
          set(:server, '--server STR', String, 'Set the key of server.')
          set(:node, '--node STR', String, 'Set the comma sparated key of nodes.')
          set(:no_server, '--no-server', 'Not execute server.')
          set(:no_node, '--no-node', 'Not execute node.')
        end
        setting.set_argument(*args)
      end
    end
  end
end
