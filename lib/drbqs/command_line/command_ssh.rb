module DRbQS
  class Command
    class SSH < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
  Execute command over SSH.
  <command> is 'list', 'show', 'environment', 'execute', 'server', or 'node'.

  #{@@command_name} list
  #{@@command_name} show <configuration>
  #{@@command_name} environment <destination>
  #{@@command_name} execute <destination> [options ...] -- [arguments ...]
  #{@@command_name} server <destination> [options ...] -- [arguments ...]
  #{@@command_name} node <destination> [options ...] -- [arguments ...]

HELP

      def initialize
        super(DRbQS::Setting::SSH, HELP_MESSAGE)
      end

      def parse_option(argv)
        args, mode_args = split_arguments(argv)
        args = option_parser_base(args, :debug => true) do |opt|
          set(:directory, '-d DIR', '--directory DIR', String, 'Set the base directory over ssh.')
          set(:shell, '--shell STR', String, 'Set the shell over ssh')
          set(:rvm, '--rvm STR', String, 'Ruby version to use on RVM over ssh.')
          set(:rvm_init, '--rvm-init PATH', String, 'Path of script to initialize RVM over ssh.')
          set(:output, '-o DIR', '--output DIR', String, 'Directory path that a server and nodes output.')
          set(:nice, '--nice NUM', Integer, 'Set the value of nice for a server and nodes. The default is 10.')
        end
        setting.set_argument(*args)
        case setting.get_argument[0]
        when 'server'
          parser = DRbQS::Command::Server.new
          parser.parse_option(mode_args)
          setting.mode_setting = parser.setting
        when 'node'
          parser = DRbQS::Command::Node.new
          parser.parse_option(mode_args)
          setting.mode_setting = parser.setting
        when 'execute'
          setting.configure_mode_setting(:execute) do |mode_setting|
            mode_setting.argument.concat(mode_args)
          end
        end
      end
    end
  end
end

