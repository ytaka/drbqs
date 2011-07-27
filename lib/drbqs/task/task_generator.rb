module DRbQS
  class DRbQS::TaskCreatingError < StandardError
  end

  class TaskSource
    def initialize(data)
      data.each do |key, val|
        instance_variable_set("@#{key.to_s}", val)
      end
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
      add_task(DRbQS::Task.new(*args, &block))
    end

    def wait_all_tasks
      Fiber.yield(:wait)
    end
  end

  class TaskGenerator
    def initialize(data = {})
      @source = DRbQS::TaskSource.new(data)
      @fiber = nil
      @iterate = nil
      @task_set = nil
      @fiber_init = nil
      @wait = false
    end

    def have_next?
      !!@fiber
    end

    def waiting?
      @wait
    end

    # The options :generate and :collect are available.
    # opts[:generate] is the number of tasks per one generation.
    # The generator creates a task set from opts[:collect] tasks.
    def set(opts = {}, &block)
      @iterate = opts[:generate] || 1
      @task_set = opts[:collect]
      if @iterate < 1 || (@task_set && @task_set < 1)
        raise ArgumentError, "Invalid options of task creation on generator."
      end
      @fiber_init = lambda do
        @fiber = Fiber.new do
          begin
            @source.instance_eval(&block)
          rescue => err
            new_err = DRbQS::TaskCreatingError.new("#{err.to_s} (#{err.class}) when creating task")
            new_err.set_backtrace(err.backtrace)
            raise new_err
          end
          nil
        end
      end
    end

    # Initialize fider to create tasks.
    # This method must be called in thread to create tasks.
    def init
      @fiber_init.call if @fiber_init
    end

    # Return an array of new tasks.
    def new_tasks
      if @fiber
        @wait = false
        task_ary = []
        iteration = @iterate
        iteration *= @task_set if @task_set
        iteration.times do |i|
          if task_new = @fiber.resume
            case task_new
            when DRbQS::Task
              task_ary << task_new
            when Array
              task_ary.concat(task_new)
            when :wait
              @wait = true
              break
            else
              raise "Invalid type of new task."
            end
          else
            @fiber = nil
            break
          end
        end
        if task_ary.size > 0
          if @task_set
            task_ary = task_ary.each_slice(@task_set).map do |ary|
              DRbQS::TaskSet.new(ary)
            end
          end
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
