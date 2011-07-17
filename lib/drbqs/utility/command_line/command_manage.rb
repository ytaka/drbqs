module DRbQS
  class CommandManage < CommandBase
    HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
Manage DRbQS server by sending messages.
<command> is 'signal', 'status', 'process', or 'initialize'.

  #{@@command_name} signal <uri> server-exit
  #{@@command_name} signal <uri> node-exit-after-task <node_number>
  #{@@command_name} status <uri>
  #{@@command_name} process
  #{@@command_name} process clear
  #{@@command_name} initialize

HELP

    def parse_options(argv)
      begin
        OptionParser.new(HELP_MESSAGE) do |opt|
          opt.on('--debug', 'Set $DEBUG true.') do |v|
            $DEBUG = true
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
      @mode = argv.shift
      @argv = argv
      @manage = DRbQS::Manage.new
    end

    def command_initialize
      check_argument_size(@argv, :>=, 0, :<=, 1)
      @manage.set_home_directory(@argv[0])
      @manage.create_config
      exit_normally
    end
    private :command_initialize

    def command_process
      check_argument_size(@argv, :>=, 0, :<=, 1)
      if @argv[0] == 'clear'
        @manage.clear_process
        exit_normally
      end
      list = @manage.list_process
      $stdout.puts "Server"
      list[:server].each do |uri, data|
        $stdout.puts "#{uri}"
        data.each do |k, v|
          $stdout.puts sprintf("  %-10s  %s", k, v)
        end
      end
      $stdout.puts "\nNode"
      list[:node].each do |pid, data|
        $stdout.puts "#{pid}"
        data.each do |k, v|
          $stdout.puts sprintf("  %-10s  %s", k, v)
        end
      end
      exit_normally
    end
    private :command_process

    def command_status
      check_argument_size(@argv, :==, 1)
      @manage.set_uri(@argv[0])
      if status = @manage.get_status
        $stdout.puts status
      end
      exit_normally
    end
    private :command_status

    def command_signal
      @manage.set_uri(@argv[0])
      signal = @argv[1]
      case signal
      when 'server-exit'
        check_argument_size(@argv, :==, 2)
        @manage.send_exit_signal
        exit_normally
      when 'node-exit-after-task'
        check_argument_size(@argv, :==, 3)
        node_id = @argv[2].to_i
        @manage.send_node_exit_after_task(node_id)
        exit_normally
      else
        $stderr.print "error: Invalid signal '#{signal}'\n\n" << HELP_MESSAGE
        exit_unusually
      end
    end
    private :command_signal

    def exec
      case @mode
      when 'initialize'
        command_initialize
      when 'process'
        command_process
      when 'status'
        command_status
      when 'signal'
        command_signal
      end
      $stderr.print "error: Invalid command '#{@mode}'\n\n" << HELP_MESSAGE
      exit_invalid_option
    rescue DRb::DRbConnError => err
      $stderr.puts "error: Can not connect server: #{err.to_s}"
      exit_unusually
    rescue => err
      $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
      exit_unusually
    end
  end
end
