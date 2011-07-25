module DRbQS
  class Command
    class SSH < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
  Execute command over SSH.
  <command> is 'list', 'show', 'execute', or 'environment'

  #{@@command_name} list
  #{@@command_name} show <configuration>
  #{@@command_name} environment <destination>
  #{@@command_name} execute <destination> [options ...]
  #{@@command_name} server <destination> [options ...] -- [arguments ...]
  #{@@command_name} node <destination> [options ...] -- [arguments ...]

HELP

      def initialize
        super(DRbQS::Setting::SSH)
      end

      def parse_option(argv)
        args, ssh_args = split_arguments(argv)
        args = option_parser_base(args, HELP_MESSAGE, :debug => true) do |opt|
          opt.on('--dir DIR', String, 'Set the base directory over ssh.') do |v|
            @setting.set(:dir, v)
          end
          opt.on('--shell STR', String, 'Set the shell over ssh') do |v|
            @setting.set(:shell, v)
          end
          opt.on('--rvm STR', String, 'Ruby version to use on RVM over ssh.') do |v|
            @setting.set(:rvm, v)
          end
          opt.on('--rvm-init PATH', String, 'Path of script to initialize RVM over ssh.') do |v|
            @setting.set(:rvm_init, v)
          end
          opt.on('--output DIR', String, 'Directory path that a server and nodes output.') do |v|
            @setting.set(:output, v)
          end
          opt.on('--nice NUM', Integer, 'Set the value of nice for a server and nodes. The default is 10.') do |v|
            @setting.set(:nice, v)
          end
        end
        @setting.set_argument(*args)
        @setting.set_ssh_argument(*ssh_args)
      end

      def exec
        @setting.parse!
        @setting.exec($stdout)
      rescue => err
        $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
        exit_unusually
      end
    end
  end
end

