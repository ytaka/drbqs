require 'drbqs/utility/setting'

module DRbQS
  class Command
    class Base
      include DRbQS::Misc
      include DRbQS::Command::Argument

      @@command_name = File.basename($PROGRAM_NAME)

      def self.exec(argv)
        obj = self.new
        obj.parse_option(argv)
        obj.exec
      end

      def initialize(klass)
        @setting = klass.new
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

      def option_parser_base(argv, help_message, options = {}, &block)
        begin
          OptionParser.new(help_message) do |opt|
            yield(opt) if block_given?
            if options[:log_level]
              opt.on('--log-level LEVEL', String,
                     "Set the log level. The value accepts 'fatal', 'error', 'warn', 'info', and 'debug'. The default is 'error'.") do |v|
                @setting.set(:log_level, v)
              end
            end
            if options[:daemon]
              opt.on('--daemon OUT', String, 'Execute as daemon and set output file for stdout and stderr.') do |v|
                @setting.set(:daemon, v)
              end
            end
            if options[:debug]
              opt.on('--debug', 'Set $DEBUG true.') do |v|
                @setting.set(:debug)
              end
            end
            opt.parse!(argv)
          end
        rescue DRbQS::Setting::InvalidLogLevel => err
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
    end
  end
end
