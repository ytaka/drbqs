module DRbQS
  class Command
    class Server < DRbQS::Command::Base
      @@command_name = File.basename($PROGRAM_NAME)

      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition.rb> [other files ...] [options ...]
       #{@@command_name} <definition.rb> [other files ...] [options ...] -- [server options ...]
  Start DRbQS server of definition files.

HELP

      def initialize
        super(DRbQS::Setting::Server)
      end

      def parse_option(argv)
        command_argv, server_argv = split_arguments(argv)

        command_argv = option_parser_base(command_argv, HELP_MESSAGE, :log_level => true, :daemon => true, :debug => true) do |opt|
          opt.on('-p PORT', '--port', Integer, 'Set the port number of server.') do |v|
            @setting.set(:port, v)
          end
          opt.on('-u PATH', '--unix', String, 'Set the path of unix domain socket.') do |v|
            @setting.set(:unix, v)
          end
          opt.on('--acl FILE', String, 'Set a file to define ACL.') do |v|
            @setting.set(:acl, v)
          end
          opt.on('--log-file STR', String, "Set the path of log file. If this options is not set, use STDOUT.") do |v|
            @setting.set(:log_file, v)
          end
          opt.on('--sftp-user USER', String, 'Set the user of sftp destination.') do |v|
            @setting.set(:sftp_user, v)
          end
          opt.on('--sftp-host HOST', String, 'Set the host of sftp destination.') do |v|
            @setting.set(:sftp_host, v)
          end
          opt.on('--profile', 'Use profile for test exec.') do |v|
            @setting.set(:profile)
          end
          opt.on('--profile-printer PRINTER', String,
                 'Set the printer type for profile. The value is :flat, :graph, :graphhtml, or :calltree.') do |v|
            @setting.set(:profile_printer, v)
          end
          opt.on('--test STR', String, 'Execute test.') do |v|
            @setting.set(:test, v)
          end
          opt.on('--execute-node NUM', Integer, 'Execute nodes.') do |v|
            @setting.set(:execute_node, v)
          end
          opt.on('-h', '--help', 'Show this command help and server specific help.') do |v|
            $stdout.print opt
            @setting.set(:help)
          end
        end
        @setting.set_argument(*command_argv)
        @setting.set_server_argument(*server_argv)
      end
    end
  end
end
