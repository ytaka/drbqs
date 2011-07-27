module DRbQS
  class Command
    class Execute < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition> [arguments ...]
  Execute DRbQS server and some nodes from definition file.

HELP

      def initialize
        super(DRbQS::Setting::Execute)
      end

      def parse_option(argv)
        args = option_parser_base(argv, HELP_MESSAGE) do |opt|
          opt.on('--port NUM', Integer, 'Set the port number.') do |v|
            @setting.set(:port, v)
          end
          opt.on('--server STR', String, 'Set the key of server.') do |v|
            @setting.set(:server, v)
          end
          opt.on('--node STR', String, 'Set the comma sparated key of nodes.') do |v|
            @setting.set(:node, v)
          end
          opt.on('--no-server', 'Not execute server.') do |v|
            @setting.set(:no_server)
          end        
          opt.on('--no-node', 'Not execute node.') do |v|
            @setting.set(:no_node)
          end
        end
        @setting.set_argument(*args)
      end
    end
  end
end
