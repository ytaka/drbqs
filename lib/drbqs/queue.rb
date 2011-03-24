module DRbQS

  class QueueServer
    attr_reader :calculating

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
    # Return task ID (for debug).
    def add(task)
      @task_id += 1
      @logger.info("New task: #{@task_id}") if @logger
      @cache[@task_id] = task
      queue_task(@task_id)
      @task_id
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
      rescue Rinda::RequestExpiredError
        @logger.debug("Accept: #{count} signals.") if @logger
      end
      count
    end

    def requeue_for_deleted_node_id(deleted)
      deleted.each do |node_id|
        if task_id_ary = @calculating[node_id]
          task_id_ary.each do |task_id|
            queue_task(task_id)
            @logger.info("Requeue: task #{task_id}.") if @logger
          end
          @calculating.delete(node_id)
        end
      end
    end

    def get_result
      count = 0
      begin
        loop do
          get_accept_signal
          sym, task_id, node_id, result = @result.take([:result, Fixnum, Fixnum, nil], 0)
          count += 1
          @logger.info("Get: result of #{task_id} from node #{node_id}.") if @logger
          unless @calculating[node_id].delete(task_id)
            @logger.error("Task #{task_id} does not exist in list of calculating tasks.") if @logger
          end
          if ary = @calculating.find { |k, v| v.include?(task_id) }
            @logger.error("Node #{ary[0]} is calculating task #{task_id}, too.") if @logger
          end
          if task = @cache.delete(task_id)
            if hook = task.hook
              hook.call(self, result)
            end
          else
            @logger.error("Task #{task_id} is not cached.") if @logger
          end
        end
      rescue Rinda::RequestExpiredError
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
