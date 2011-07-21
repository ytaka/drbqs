module DRbQS
  class CommandBase
    class InvalidLogLevel < StandardError
    end

    include DRbQS::CommandLineArgument
    @@command_name = File.basename($PROGRAM_NAME)

    def self.exec(argv)
      obj = self.new
      obj.parse_option(argv)
      obj.exec
    end

    def initialize
      @daemon = nil
    end

    def exit_normally
      Kernel.exit(0)
    end
    private :exit_normally

    def exit_unusually
      Kernel.exit(1)
    end
    private :exit_unusually

    def exit_invalid_option
      Kernel.exit(2)
    end
    private :exit_invalid_option

    def parse_log_level(str)
      if /^(fatal)|(error)|(warn)|(info)|(debug)$/i =~ str
        eval("Logger::#{str.upcase}")
      else
        raise DRbQS::CommandBase::InvalidLogLevel, "error: Invalid log level '#{str}'"
      end
    end
    private :parse_log_level

    def option_parser_base(argv, help_message, options = {}, &block)
      begin
        OptionParser.new(help_message) do |opt|
          yield(opt) if block_given?
          if options[:daemon]
            opt.on('--daemon OUT', String, 'Execute as daemon and set output file for stdout and stderr.') do |v|
              @daemon = v
            end
          end
          if options[:debug]
            opt.on('--debug', 'Set $DEBUG true.') do |v|
              $DEBUG = true
            end
          end
          opt.parse!(argv)
        end
      rescue DRbQS::CommandBase::InvalidLogLevel => err
        $stderr.print err.to_s << "\n\n" << help_message
        exit_invalid_option
      rescue OptionParser::InvalidOption
        $stderr.print "error: Invalid Option\n\n" << help_message
        exit_invalid_option
      rescue OptionParser::InvalidArgument
        $stderr.print "error: Invalid Argument\n\n" << help_message
        exit_invalid_option
      end
      argv
    end
    private :option_parser_base

    def daemon_start(output, &block)
      Process.daemon(true)
      begin
        $stdout = Kernel.open(output, 'w')
        $stderr = $stdout
        begin
          yield
        rescue SystemExit
          return 0
        end
      rescue Exception => err
        backtrace = err.backtrace
        $stderr.puts "#{backtrace[0]}: #{err.to_s} (#{err.class})"
        if backtrace.size > 1
          $stderr.puts "        from #{backtrace[1..-1].join("\n        from ")}"
        end
      ensure
        $stdout.close
      end
    end
    private :daemon_start

    def exec_as_daemon
      if @daemon
        @daemon = FileName.create(@daemon, :position => :middle, :type => :time, :directory => :parent)
        daemon_start(@daemon) do
          @daemon = nil
          exec
        end
        true
      else
        nil
      end
    end
    private :exec_as_daemon
  end
end
