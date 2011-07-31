module DRbQS
  # Class to define tasks such that we execute a command.
  class CommandTask < DRbQS::Task

    # Execute a command and transfer files if needed.
    class CommandExecute

      # :transfer    String or Array
      # :compress    true or false
      def initialize(cmd, opts = {})
        @cmd = cmd
        unless (Array === @cmd || String === @cmd)
          raise ArgumentError, "Invalid command: #{@cmd.inspect}"
        end
        @transfer = opts[:transfer]
        @compress = opts[:compress]
      end

      def exec
        case @cmd
        when Array
          @cmd.each { |c| system(c) }
        when String
          system(@cmd)
        end
        exit_status = $?.exitstatus
        if @transfer
          if @transfer.respond_to?(:each)
            @transfer.each { |path| DRbQS::Transfer.enqueue(path, :compress => @compress) }
          else
            DRbQS::Transfer.enqueue(@transfer, :compress => @compress)
          end
        end
        exit_status
      end
    end

    # &hook takes a server instance and exit number of command.
    def initialize(cmd, opts = {}, &hook)
      super(DRbQS::CommandTask::CommandExecute.new(cmd, opts), :exec, &hook)
    end
  end
end
