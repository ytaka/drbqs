module DRbQS
  class TaskClient
    def initialize(node_id, queue, result, logger = nil)
      @node_id = node_id
      @queue = queue
      @result = result
      @calculating_task = nil
      @task_queue = Queue.new
      @result_queue = Queue.new
      @logger = logger
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
      if @result_queue.size > 0
        result = @result_queue.deq
        @logger.info("Send result: #{@calculating_task}") { result.inspect } if @logger
        @result.write([:result, @calculating_task, result])
        @calculating_task = nil
      end
    end

    def get
      @task_queue.deq
    end

    def transmit(result)
      @result_queue.enq(result)
    end

    def dump_result_queue
      results = []
      while @result_queue.size > 0
        results << @result_queue.deq
      end
      if results.size > 0
        Marshal.dump(results)
      else
        nil
      end
    end

  end

end
