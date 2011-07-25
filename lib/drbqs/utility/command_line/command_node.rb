module DRbQS
  class Command
    class Node < DRbQS::Command::Base
      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} [<uri>] [<process_number>] [options ...]
  Start DRbQS nodes connecting to <uri>.

HELP

      def initialize
        super(DRbQS::Setting::Node)
      end

      def parse_option(argv)
        argv = option_parser_base(argv, HELP_MESSAGE, :log_level => true, :daemon => true, :debug => true) do |opt|
          opt.on('-l', '--load FILE', String, 'Add a file to load.') do |v|
            @setting.set(:load, v)
          end
          opt.on('--loadavg STR', String, 'Set the threshold load average to sleep.') do |v|
            @setting.set(:loadavg, v)
          end
          opt.on('--log-prefix STR', String, "Set the prefix of log files. The default is '#{LOG_PREFIX_DEFAULT}'.") do |v|
            @setting.set(:log_prefix, v)
          end
          opt.on('--log-stdout', 'Use stdout for outputting logs. This option cancels --log-prefix.') do |v|
            @setting.set(:log_stdout)
          end
        end
        begin
          @setting.arguments(argv)
        rescue
          $stderr.print "error: Invalid arguments.\n\n" << HELP_MESSAGE
          exit_invalid_option
        end
      end

      def exec
        @setting.parse
        @setting.exec($stdout)
        exit_normally
      rescue => err
        $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
        exit_unusually
      end
    end
  end
end
