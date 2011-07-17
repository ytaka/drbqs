module DRbQS
  class CommandSSH < CommandBase
    HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
Execute command over SSH.
<command> is 'list', 'show', 'execute', or 'environment'

       #{@@command_name} list
       #{@@command_name} show name
       #{@@command_name} environment <destination>
       #{@@command_name} execute <destination>

HELP

    def parse_options(argv)
      options = {}
      argv, command_args = split_arguments(argv)

      begin
        OptionParser.new(HELP_MESSAGE) do |opt|
          opt.on('--debug', 'Set $DEBUG true.') do |v|
            $DEBUG = true
          end
          opt.on('--dir DIR', String, 'Set the base directory over ssh.') do |v|
            options[:dir] = v
          end
          opt.on('--shell STR', String, 'Set the shell over ssh') do |v|
            options[:shell] = v
          end
          opt.on('--rvm STR', String, 'Ruby version to use on RVM over ssh.') do |v|
            options[:rvm] = v
          end
          opt.on('--rvm-init PATH', String, 'Path of script to initialize RVM over ssh.') do |v|
            options[:rvm_init] = v
          end
          opt.on('--output PATH', String, 'File path that stdout and stderr are output to over ssh.') do |v|
            options[:output] = v
          end
          opt.on('--nice NUM', Integer, 'Set the value for nice command.') do |v|
            options[:nice] = v
          end
          opt.on('--nohup', 'Use nohup command.') do |v|
            options[:nohup] = true
          end
          opt.parse!(argv)
        end
      rescue OptionParser::InvalidOption
        $stderr.print "error: Invalid Option\n\n" << HELP_MESSAGE
        exit_invalid_option
      rescue OptionParser::InvalidArgument
        $stderr.print "error: Invalid Argument\n\n" << HELP_MESSAGE
        exit_invalid_option
      end
      @options = options
      @command = argv.shift
      @argv = argv
      @command_args = command_args
    end

    def command_list
      ssh_host = DRbQS::Config.new.ssh_host
      $stdout.puts ssh_host.config_names.join("\n")
      exit_normally
    end
    private :command_list

    def command_show
      check_argument_size(@argv, :==, 1)
      name = @argv[0]
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
      check_argument_size(@argv, :==, 1)
      dest = @argv[0]
      manage_ssh(dest).get_environment
      exit_normally
    end
    private :command_environment

    def command_execute
      check_argument_size(@argv, :==, 1)
      dest = @argv[0]
      mng_ssh = manage_ssh(dest)
      if @command_args.size > 0
        mng_ssh.execute(@command_args)
        exit_normally
      else
        $stderr.print "error: There is no command for ssh.\n\n" << HELP_MESSAGE
        exit_unusually
      end
    end
    private :command_execute

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
      end
      $stderr.print "error: Invalid command '#{@command}'.\n\n" << HELP_MESSAGE
      exit_invalid_option
    rescue => err
      $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
      exit_unusually
    end
  end
end
