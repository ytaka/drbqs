module DRbQS
  # Class to define tasks such that we execute a command.
  class CommandTask < DRbQS::Task

    # Execute a command and transfer files if needed.
    class CommandExecute
      def initialize(cmds, opts = {})
        opts.assert_valid_keys(:transfer, :compress)
        @cmds = cmds
        if String === @cmds
          @cmds = [@cmds]
        elsif !(Array === @cmds)
          raise ArgumentError, "Invalid command: #{@cmds.inspect}"
        end
        @transfer = opts[:transfer]
        @compress = opts[:compress]
      end

      def exec
        exit_status_ary = @cmds.map do |cmd|
          system(cmd)
          $?.exitstatus
        end
        if @transfer
          if @transfer.respond_to?(:each)
            @transfer.each { |path| DRbQS::Transfer.enqueue(path, :compress => @compress) }
          else
            DRbQS::Transfer.enqueue(@transfer, :compress => @compress)
          end
        end
        exit_status_ary
      end
    end

    # @override initialize(*cmds, opts = {}, &hook)
    #  @param [Array] cmds An array of commands which are string or array, that is, arguments of the method 'system'.
    #  @param [Hash] opts Hash of options
    #  @param [Proc] hook Block same as that of DRbQS::Task object, which takes a server instance and an array of exit statuses.
    #  @option opts [String,Array] :transfer Paths to be transfered after finish of commands
    #  @option opts [boolean] :compress Compress files before transfering or not
    def initialize(*args, &hook)
      opts = args.extract_options!
      super(DRbQS::CommandTask::CommandExecute.new(args, opts), :exec, &hook)
    end
  end
end
