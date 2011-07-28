module DRbQS
  class Command
    class Execute < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition> [options ...]
       #{@@command_name} <definition> [options ...] [-- server options ...]
  Execute DRbQS server and some nodes from definition file.

HELP

      def initialize
        super(DRbQS::Setting::Execute, HELP_MESSAGE)
      end

      def parse_option(argv)
        args, server_args = split_arguments(argv)
        args = option_parser_base(args) do
          set(:port, '--port NUM', Integer, 'Set the port number.')
          set(:server, '--server STR', String, 'Set the key of server.')
          set(:node, '--node STR', String, 'Set the comma sparated key of nodes.')
          set(:no_server, '--no-server', 'Not execute server.')
          set(:no_node, '--no-node', 'Not execute node.')
          set(:information, '-i', '--information', 'Show information.')
          set(:help, '-h', '--help', 'Show this command help and usage of definition file.') do |opt|
            $stdout.print opt
          end
        end
        setting.set_argument(*args)
        setting.server_argument = server_args
      end
    end
  end
end
