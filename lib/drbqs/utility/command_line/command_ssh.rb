module DRbQS
  class CommandSSH < CommandBase
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

    def parse_option(argv)
      @options = {
        :io => $stdout
      }
      @nice = 10
      @output = nil
      argv, @command_args = split_arguments(argv)
      @argv = option_parser_base(argv, HELP_MESSAGE, :debug => true) do |opt|
        opt.on('--dir DIR', String, 'Set the base directory over ssh.') do |v|
          @options[:dir] = v
        end
        opt.on('--shell STR', String, 'Set the shell over ssh') do |v|
          @options[:shell] = v
        end
        opt.on('--rvm STR', String, 'Ruby version to use on RVM over ssh.') do |v|
          @options[:rvm] = v
        end
        opt.on('--rvm-init PATH', String, 'Path of script to initialize RVM over ssh.') do |v|
          @options[:rvm_init] = v
        end
        opt.on('--output DIR', String, 'Directory path that a server and nodes output.') do |v|
          @output = v
        end
        opt.on('--nice NUM', Integer, 'Set the value of nice for a server and nodes. The default is 10.') do |v|
          @nice = v
        end
      end
      @command = @argv.shift
    end

    def command_list
      ssh_host = DRbQS::Config.new.ssh_host
      $stdout.puts ssh_host.config_names.join("\n")
      exit_normally
    end
    private :command_list

    def only_first_argument
      check_argument_size(@argv, :==, 1)
      @argv[0]
    end
    private :only_first_argument

    def command_show
      name = only_first_argument
      ssh_host = DRbQS::Config.new.ssh_host
      if path = ssh_host.get_path(name)
        $stdout.puts File.read(path)
        exit_normally
      else
        $stderr.print "Can not find configuration file '#{name}'."
        exit_unusually
      end
    end
    private :command_show

    def manage_ssh(dest)
      DRbQS::Manage::SSHExecute.new(dest, @options)
    end
    private :manage_ssh

    def command_environment
      dest = only_first_argument
      manage_ssh(dest).get_environment
      exit_normally
    end
    private :command_environment

    def command_execute
      dest = only_first_argument
      mng_ssh = manage_ssh(dest)
      if @command_args.size > 0
        mng_ssh.command(@command_args)
        exit_normally
      else
        $stderr.print "error: There is no command for ssh.\n\n" << HELP_MESSAGE
        exit_unusually
      end
    end
    private :command_execute

    def command_server
      dest = only_first_argument
      manage_ssh(dest).server(@command_args, :nice => @nice, :daemon => @output)
      exit_normally
    end
    private :command_server

    def command_node
      dest = only_first_argument
      manage_ssh(dest).node(@command_args, :nice => @nice, :daemon => @output)
      exit_normally
    end
    private :command_node

    def exec
      case @command
      when 'list'
        command_list
      when 'show'
        command_show
      when 'environment'
        command_environment
      when 'execute'
        command_execute
      when 'server'
        command_server
      when 'node'
        command_node
      end
      $stderr.print "error: Invalid command '#{@command}'.\n\n" << HELP_MESSAGE
      exit_invalid_option
    rescue => err
      $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
      exit_unusually
    end
  end
end
