module DRbQS
  class TaskGenerator
    def initialize(data = {})
      data.each do |key, val|
        instance_variable_set("@#{key.to_s}", val)
      end
      @__fiber__ = nil
      @__iterate__ = nil
    end

    def have_next?
      !!@__fiber__
    end

    def create_add_task(*args, &block)
      Fiber.yield(DRbQS::Task.new(*args, &block))
    end

    def set(iterate = 1, &block)
      @__iterate__ = iterate
      @__fiber__ = Fiber.new do
        instance_eval(&block)
        nil
      end
    end

    # Return an array of new tasks.
    def new_tasks
      if @__fiber__
        task_ary = []
        @__iterate__.times do |i|
          if task_new = @__fiber__.resume
            case task_new
            when DRbQS::Task
              task_ary << task_new
            when Array
              task_ary.concat(task_new)
            else
              raise "Invalid type of new task."
            end
          else
            @__fiber__ = nil
            break
          end
        end
        if task_ary.size > 0
          return task_ary
        end
      end
      nil
    end

    # Create all tasks for test and return true if all tasks created properly.
    def debug_all_tasks(limit = nil)
      i = 0
      while ary = new_tasks
        ary.each? do |t|
          unless DRbQS::TaskGenerator === t
            raise "Invalid task by #{i}th generation: #{t.inspect}"
          end
        end
        i += 1
      end
      true
    end
  end
end
