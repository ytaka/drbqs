module DRbQS
  class Task
    class Generator
      # @param [Hash] data This argument is unnecessary and so deprecated
      #  Names of instance variables and their values,
      #  which can be accessed in {DRbQS::Task::Generator#set}.
      def initialize(data = {})
        @registrar = DRbQS::Task::Registrar.new(data)
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

      # Specify how to generate tasks.
      # @param [Hash] opts The options of task generation
      # @option opts [Fixnum] :generate Set the number of tasks per one generation
      # @option opts [Fixnum] :collect The generator creates a task set consisting of opts[:collect] tasks.
      def set(opts = {}, &block)
        unless block_given?
          raise ArgumentError, "Creation of a task generator needs block."
        end
        @iterate = opts[:generate] || 1
        @task_set = opts[:collect]
        if @iterate < 1 || (@task_set && @task_set < 1)
          raise ArgumentError, "Invalid options of task creation on generator."
        end
        @fiber_init = lambda do
          @fiber = Fiber.new do
            begin
              @registrar.instance_eval(&block)
            rescue => err
              new_err = err.class.new("Error on generating tasks: #{err.to_s} (#{err.class})")
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
                raise RuntimeError, "Invalid object created by fiber to create tasks."
              end
            else
              @fiber = nil
              break
            end
          end
          if task_ary.size > 0
            if @task_set
              task_ary = task_ary.each_slice(@task_set).map do |ary|
                DRbQS::Task::TaskSet.new(ary)
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
              raise RuntimeError, "Invalid #{i}th task: #{t.inspect}"
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
end
