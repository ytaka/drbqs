module DRbQS
  class CommandBase
    include DRbQS::CommandLineArgument
    @@command_name = File.basename($PROGRAM_NAME)

    def self.exec(argv)
      obj = self.new
      obj.parse_options(argv)
      obj.exec
    end

    def exit_normally
      exit(0)
    end
    private :exit_normally

    def exit_unusually
      exit(1)
    end
    private :exit_unusually

    def exit_invalid_option
      exit(2)
    end
    private :exit_invalid_option
  end
end
