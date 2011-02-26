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

  class QueueServer

    def initialize(queue, result, logger = nil)
      @queue = queue
      @result = result
      @task_id = 0
      @cache = {}
      @calculating = Hash.new { |hash, key| hash[key] = Array.new }
      @logger = logger
    end

    def queue_task(task_id)
      @queue.write(@cache[task_id].drb_args(task_id))
    end
    private :queue_task

    # &hook take two arguments: a QueueServer object and a result of task.
    def add(task)
      @task_id += 1
      @logger.info("New task: #{@task_id}") if @logger
      @cache[@task_id] = task
      queue_task(@task_id)
    end

    def get_accept_signal
      count = 0
      begin
        loop do
          sym, task_id, node_id = @result.take([:accept, Fixnum, Fixnum], 0)
          count += 1
          @calculating[node_id] << task_id
          @logger.info("Accept: task #{task_id} by node #{node_id}.") if @logger
        end
      rescue
        @logger.debug("Accept: #{count} signals.") if @logger
      end
      count
    end

    def requeue_for_deleted_node_id(deleted)
      deleted.each do |node_id|
        if task_id_ary = @calculating[node_id]
          task_id_ary.each { |task_id| queue_task(task_id) }
          @calculating.delete(node_id)
        end
      end
    end

    def get_result
      count = 0
      begin
        loop do
          get_accept_signal
          sym, task_id, result = @result.take([:result, Fixnum, nil], 0)
          count += 1
          if ary = @calculating.find { |k, v| v.include?(task_id) }
            node_id = ary[0]
            @calculating[node_id].delete(task_id)
          else
            node_id = nil
          end
          @logger.info("Get: result of #{task_id} from node #{node_id}.") if @logger
          task = @cache.delete(task_id)
          if hook = task.hook
            hook.call(self, result)
          end
        end
      rescue
        @logger.debug("Get: #{count} results.") if @logger
      end
      count
    end

    def calculating_task_number
      @calculating.inject(0) { |s, key_val| s + key_val[1].size }
    end

    # If queue is empty, return true. Otherwise, false.
    # Even if there are calculating tasks,
    # the method can return true.
    def empty?
      @cache.size - calculating_task_number == 0
    end

    # If there are no tasks in queue and calculating,
    # return true. Otherwise, false.
    def finished?
      @cache.size == 0
    end
  end

end
