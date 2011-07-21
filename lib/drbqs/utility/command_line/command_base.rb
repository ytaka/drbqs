module DRbQS
  class CommandBase
    include DRbQS::CommandLineArgument
    @@command_name = File.basename($PROGRAM_NAME)

    def initialize
      @daemon = nil
    end

    def self.exec(argv)
      obj = self.new
      obj.parse_option(argv)
      obj.exec
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
