module DRbQS
  class TaskClient
    attr_reader :node_id

    def initialize(node_id, queue, result, logger = nil)
      @node_id = node_id
      @queue = queue
      @result = result
      @calculating_task = nil
      @task_queue = Queue.new
      @result_queue = Queue.new
      @logger = logger
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

    def dequeue_task
      @task_queue.deq
    end

    def add_new_task
      unless @calculating_task
        begin
          task_id, obj, method_sym, args = @queue.take([Fixnum, nil, Symbol, nil], 0)
          @calculating_task = task_id
          @task_queue.enq([obj, method_sym, args])
          @logger.info("Send accept signal: node #{@node_id} caluclating #{@calculating_task}") if @logger
          @result.write([:accept, @calculating_task, @node_id])
        rescue Rinda::RequestExpiredError
        end
      end
    end

    def send_result
      if !result_empty?
        result = dequeue_result
        @logger.info("Send result: #{@calculating_task}") { result.inspect } if @logger
        @result.write([:result, @calculating_task, result])
        @calculating_task = nil
      end
    end

    def transmit(result)
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
