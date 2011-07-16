module DRbQS
  class CommandBase
    def exit_normally
      exit(0)
    end
    private :exit_normally

    def exit_unusually
      exit(1)
    end
    private :exit_unusually
  end
end
