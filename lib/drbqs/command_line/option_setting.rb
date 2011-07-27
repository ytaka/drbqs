module DRbQS
  class Command
    class OptionSetting
      attr_reader :setting

      def initialize(help_message, setting)
        @opt_parser = OptionParser.new(help_message)
        @setting = setting
      end

      def set(*args, &block)
        unless @setting
          raise "Not in method 'define'."
        end
        @opt_parser.on(*args[1..-1]) do |v|
          @setting.set(args[0], v)
          if block_given?
            yield(@opt_parser)
          end
        end
      end

      def define(options = {}, &block)
        instance_eval(&block) if block_given?
        if options[:log_level]
          set(:log_level, '--log-level LEVEL', String,
              "Set the log level. The value accepts 'fatal', 'error', 'warn', 'info', and 'debug'. The default is 'error'.")
        end
        if options[:daemon]
          set(:daemon, '--daemon OUT', String, 'Execute as daemon and set output file for stdout and stderr.')
        end
        if options[:debug]
          set(:debug, '--debug', 'Set $DEBUG true.')
        end
      end

      def parse!(argv)
        @opt_parser.parse!(argv)
      end
    end
  end
end
