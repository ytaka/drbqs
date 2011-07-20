module DRbQS
  class CommandManage < CommandBase
    HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <command> [arguments ...]
  Manage DRbQS server by sending messages.
  <command> is 'signal', 'status', 'process', or 'initialize'.

  #{@@command_name} signal <uri> server-exit
  #{@@command_name} signal <uri> node-exit-after-task <node_number>
  #{@@command_name} signal <uri> node-wake <node_number>
  #{@@command_name} signal <uri> node-sleep <node_number>
  #{@@command_name} status <uri>
  #{@@command_name} history <uri>
  #{@@command_name} process list
  #{@@command_name} process clear
  #{@@command_name} initialize

HELP

    def parse_option(argv)
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

    def request_to_server(method_name)
      check_argument_size(@argv, :==, 1)
      @manage.set_uri(@argv[0])
      if status = @manage.__send__(method_name)
        $stdout.puts status
      end
      exit_normally
    end
    private :request_to_server

    def command_status
      request_to_server(:get_status)
    end
    private :command_status

    def command_history
      request_to_server(:get_history)
    end
    private :command_history

    def signal_to_node(method_name)
      check_argument_size(@argv, :==, 3)
      node_id = @argv[2].to_i
      @manage.__send__(method_name, node_id)
      exit_normally
    end
    private :signal_to_node

    def command_signal
      @manage.set_uri(@argv[0])
      signal = @argv[1]
      case signal
      when 'server-exit'
        check_argument_size(@argv, :==, 2)
        @manage.send_exit_signal
        exit_normally
      when 'node-exit-after-task'
        signal_to_node(:send_node_exit_after_task)
      when 'node-wake'
        signal_to_node(:send_node_wake)
      when 'node-sleep'
        signal_to_node(:send_node_sleep)
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
      when 'history'
        command_history
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
