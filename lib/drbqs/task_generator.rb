module DRbQS
  class DRbQS::TaskCreatingError < StandardError
  end

  class TaskGenerator
    def initialize(data = {})
      data.each do |key, val|
        instance_variable_set("@#{key.to_s}", val)
      end
      @__fiber__ = nil
      @__iterate__ = nil
      @__fiber_init__ = nil
    end

    def have_next?
      !!@__fiber__
    end

    def add_task(arg)
      case arg
      when DRbQS::Task
        Fiber.yield(arg)
      when Array
        arg.each { |t| Fiber.yield(t) }
      else
        raise "Invalid type of an argument."
      end
    end

    def create_add_task(*args, &block)
      Fiber.yield(DRbQS::Task.new(*args, &block))
    end

    def set(iterate = 1, &block)
      @__iterate__ = iterate
      @__fiber_init__ = lambda do
        @__fiber__ = Fiber.new do
          begin
            instance_eval(&block)
          rescue => err
            raise DRbQS::TaskCreatingError, "\n  #{err.to_s}"
          end
          nil
        end
      end
    end

    def init
      @__fiber_init__.call if @__fiber_init__
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

    DEBUG_TASK_PROGRESS = 1000

    # Create all tasks for test and return [group_number, task_number] if all tasks created properly.
    def debug_all_tasks(opts = {})
      limit = opts[:limit]
      progress = opts[:progress]
      group_number = 0
      task_number = 0
      while ary = new_tasks
        ary.each do |t|
          unless DRbQS::Task === t
            raise "Invalid #{i}th task: #{t.inspect}"
          end
          task_number += 1
          if progress && (task_number % DEBUG_TASK_PROGRESS == 0)
            puts "#{task_number} tasks have been created."
          end
          if limit && task_number > limit
            break
          end
        end
        group_number += 1
      end
      [group_number, task_number]
    end
  end
end
