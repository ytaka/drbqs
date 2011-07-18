module DRbQS
  class CommandBase
    include DRbQS::CommandLineArgument
    @@command_name = File.basename($PROGRAM_NAME)

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
  end
end
