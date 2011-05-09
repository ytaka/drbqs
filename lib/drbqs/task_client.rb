module DRbQS
  class TaskClient
    attr_reader :node_id, :calculating_task

    def initialize(node_id, queue, result, logger = nil)
      @node_id = node_id
      @queue = queue
      @result = result
      @calculating_task = nil
      @exit_after_task = nil
      @task_queue = Queue.new
      @result_queue = Queue.new
      @logger = logger
    end

    def calculating?
      !!@calculating_task
    end

    def task_empty?
      @task_queue.empty?
    end

    def result_empty?
      @result_queue.empty?
    end

    def dequeue_result
      @result_queue.deq
    end
    private :dequeue_result

    def queue_task(task_id, ary)
      @calculating_task = task_id
      @task_queue.enq(ary)
    end

    def dequeue_task
      @task_queue.deq
    end

    def get_task
      begin
        @queue.take([Fixnum, nil, Symbol, nil], 0)
      rescue Rinda::RequestExpiredError
        nil
      end
    end

    def set_exit_after_task
      @exit_after_task = true
    end

    def add_new_task
      if !@calculating_task && !@exit_after_task
        if ary = get_task
          task_id, obj, method_sym, args = ary
          @logger.info("Send accept signal: node #{@node_id} caluclating #{task_id}") if @logger
          @result.write([:accept, task_id, @node_id])
          queue_task(task_id, [obj, method_sym, args])
        end
      end
    end

    # If the method return true, a node should finilize and exit.
    def send_result
      if !result_empty?
        result = dequeue_result
        @logger.info("Send result: #{@calculating_task}") { result.inspect } if @logger
        @result.write([:result, @calculating_task, @node_id, result])
        @calculating_task = nil
      end
      @exit_after_task
    end

    def queue_result(result)
      @result_queue.enq(result)
    end

    def dump_result_queue
      results = []
      while !result_empty?
        results << dequeue_result
      end
      if results.size > 0
        Marshal.dump(results)
      else
        nil
      end
    end
  end

end
