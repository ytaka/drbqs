module DRbQS

  # The tasks defined by this class are sent to nodes and
  # calculated by the nodes.
  # After the node returns the result of calculation to server,
  # the server execute the hook.
  class Task
    attr_reader :hook

    # Nodes execute obj.method_sym(*args).
    # Server executes &hook with a server instance and an object of result
    # after the server accepts the results from nodes.
    def initialize(obj, method_sym, args = [], &hook)
      begin
        @marshal_obj = Marshal.dump(obj)
      rescue
        raise "Can not dump an instance of #{obj.class}."
      end
      unless Array === args
        raise "Arguments of task must be an array."
      end
      @method_sym = method_sym.intern
      @args = args
      @hook = hook
    end

    def drb_args(task_id)
      [task_id, @marshal_obj, @method_sym, @args]
    end

    def same_target?(other)
      @marshal_obj == other.instance_variable_get(:@marshal_obj) &&
        @method_sym == other.instance_variable_get(:@method_sym) &&
        @args == other.instance_variable_get(:@args)
    end
  end

  class CommandExecute
    def initialize(cmd)
      @cmd = cmd
      unless (Array === @cmd || String === @cmd)
        raise ArgumentError, "Invalid command: #{@cmd.inspect}"
      end
    end

    def exec
      case @cmd
      when Array
        @cmd.each { |c| system(c) }
      when String
        system(@cmd)
      end
      $?.exitstatus
    end
  end

  class CommandTask < Task
    # &hook takes a server instance and exit number of command.
    def initialize(cmd, &hook)
      super(CommandExecute.new(cmd), :exec, &hook)
    end
  end
end
