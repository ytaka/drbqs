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
        super(DRbQS::Setting::Server, HELP_MESSAGE)
      end

      def parse_option(argv)
        command_argv, server_argv = split_arguments(argv)

        command_argv = option_parser_base(command_argv, :log_level => true, :daemon => true, :debug => true) do
          set(:port, '-p PORT', '--port', Integer, 'Set the port number of server.')
          set(:unix, '-u PATH', '--unix', String, 'Set the path of unix domain socket.')
          set(:acl, '--acl FILE', String, 'Set a file to define ACL.')
          set(:log_file, '--log-file STR', String, "Set the path of log file. If this options is not set, use STDOUT.")
          set(:sftp_user, '--sftp-user USER', String, 'Set the user of sftp destination.')
          set(:sftp_host, '--sftp-host HOST', String, 'Set the host of sftp destination.')
          set(:profile, '--profile', 'Use profile for test exec.')
          set(:profile_printer, '--profile-printer PRINTER', String,
              'Set the printer type for profile. The value is :flat, :graph, :graphhtml, or :calltree.')
          set(:test, '--test STR', String, 'Execute test.')
          set(:execute_node, '--execute-node NUM', Integer, 'Execute nodes.')
          set(:help, '-h', '--help', 'Show this command help and server specific help.') do |opt|
            $stdout.print opt
          end
        end
        setting.set_argument(*command_argv)
        setting.set_server_argument(*server_argv)
      end
    end
  end
end
