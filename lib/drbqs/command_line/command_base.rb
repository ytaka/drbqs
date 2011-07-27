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

      def initialize(klass =  DRbQS::Setting::Base, help_message = nil)
        @opt_setting = DRbQS::Command::OptionSetting.new(help_message, klass.new)
      end

      def setting
        @opt_setting.setting
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

      def option_parser_base(argv, options = {}, &block)
        @opt_setting.define(options, &block)
        begin
          @opt_setting.parse!(argv)
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

      def parse_arguments!
        setting.parse!
      end
      private :parse_arguments!

      def exec
        begin
          parse_arguments!
          setting.exec($stdout)
          exit_normally
        rescue DRb::DRbConnError => err
          $stderr.puts "error: Can not connect. #{err.to_s}"
          exit_unusually
        rescue DRbQS::Setting::InvalidArgument => err
          mes = "error: Invalid command argument. #{err.to_s}\n\n"
          mes << self.class.const_get(:HELP_MESSAGE) if self.class.const_defined?(:HELP_MESSAGE)
          $stderr.print mes
          exit_invalid_option
        rescue => err
          output_error(err, $stderr)
          exit_unusually
        end
      end
    end
  end
end
