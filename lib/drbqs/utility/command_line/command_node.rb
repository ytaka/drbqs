module DRbQS
  class CommandNode < CommandBase
    HELP_MESSAGE =<<HELP
Usage: #{@@command_name} [<uri>] [<process_number>] [options ...]
  Start DRbQS nodes connecting to <uri>.

HELP

    LOG_PREFIX_DEFAULT = 'drbqs_node'
    LOG_LEVEL_DEFAULT = Logger::ERROR

    def parse_option(argv)
      options = {
        :log_prefix => LOG_PREFIX_DEFAULT,
        :log_level => LOG_LEVEL_DEFAULT,
        :node_opts => {},
        :load => []
      }

      begin
        OptionParser.new(HELP_MESSAGE) do |opt|
          opt.on('-l', '--load FILE', String, 'Add a file to load.') do |v|
            options[:load] << File.expand_path(v)
          end
          opt.on('--loadavg STR', String, 'Set the threshold load average to sleep.') do |v|
            max_loadavg, sleep_time = v.split(':', -1)
            options[:node_opts][:max_loadavg] = max_loadavg && max_loadavg.size > 0 ? max_loadavg.to_f : nil
            options[:node_opts][:sleep_time] = sleep_time && sleep_time.size > 0 ? sleep_time.to_i : nil
          end
          opt.on('--log-prefix STR', String, "Set the prefix of log files. The default is '#{LOG_PREFIX_DEFAULT}'.") do |v|
            options[:log_prefix] = v
          end
          opt.on('--log-level LEVEL', String,
                 "Set the log level. The value accepts 'fatal', 'error', 'warn', 'info', and 'debug'. The default is 'error'.") do |v|
            if /^(fatal)|(error)|(warn)|(info)|(debug)$/i =~ v
              options[:log_level] = eval("Logger::#{v.upcase}")
            else
              $stderr.print "error: Invalid log level.\n\n" << HELP_MESSAGE
              exit_invalid_option
            end
          end
          opt.on('--log-stdout', 'Use stdout for outputting logs. This option cancels --log-prefix.') do |v|
            options[:log_prefix] = nil
          end
          opt.on('--daemon OUT', String, 'Execute as daemon and set output file for stdout and stderr.') do |v|
            @daemon = v
          end
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
      @options = options
      @argv = argv
      if @argv.size > 2
        $stderr.print "error: Too many arguments.\n\n" << HELP_MESSAGE
        exit_invalid_option
      end
    end

    def parse_argv_array
      process_num = 1
      uri = nil
      @argv.each do |arg|
        if /^\d+$/ =~ arg
          process_num = arg.to_i
        elsif uri
          $stderr.print "error: More than one uris is set.\n\n" << HELP_MESSAGE
          exit_invalid_option
        else
          uri = arg
        end
      end
      uri ||= DRbQS::Misc.create_uri
      [process_num, uri]
    end
    private :parse_argv_array

    def exec
      return 0 if exec_as_daemon
      process_num, uri = parse_argv_array

      @options[:load].each do |v|
        $stdout.puts "load #{v}"
        load v
      end

      $stdout.puts "Connect to #{uri}"
      $stdout.puts "Execute #{process_num} processes"

      if @options[:log_prefix]
        if /\/$/ =~ @options[:log_prefix]
          @options[:log_prefix] += 'out'
        end
      end

      exec_node = DRbQS::ExecuteNode.new(uri, @options[:log_prefix], @options[:log_level], @options[:node_opts])
      exec_node.execute(process_num)
      exec_node.wait
      exit_normally
    rescue => err
      $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
      exit_unusually
    end
  end
end
