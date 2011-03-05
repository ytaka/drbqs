module DRbQS
  class Task
    attr_reader :hook

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
  end

end
