module DRbQS
  class Node
    class TaskClient
      attr_reader :node_number, :group

      def initialize(node_number, queue, result, group, logger = DRbQS::Misc::LoggerDummy.new)
        @node_number = node_number
        @queue = queue
        @result = result
        @task_queue = Queue.new
        @result_queue = Queue.new
        @group = group || []
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

      # @param [Array] ary An array is [task_id, obj, method_name, args]
      def queue_task(ary)
        @task_queue.enq(ary)
      end

      def dequeue_task
        if @task_queue.empty?
          nil
        else
          @task_queue.deq
        end
      end

      def get_task_by_group(grp)
        begin
          @queue.take([grp, Fixnum, nil, Symbol, nil], 0)[1..-1]
        rescue Rinda::RequestExpiredError
          nil
        end
      end

      def get_task
        @group.each do |grp|
          if task = get_task_by_group(grp)
            return task
          end
        end
        get_task_by_group(DRbQS::Task::DEFAULT_GROUP)
      end

      def add_new_task(num)
        get_task_id = []
        num.times do |i|
          if ary = get_task
            task_id = ary[0]
            @logger.info("Send accept signal: node #{@node_number} caluclating #{task_id}")
            @result.write([:accept, task_id, @node_number])
            queue_task(ary)
            get_task_id << task_id
          else
            break
          end
        end
        get_task_id.empty? ? nil: get_task_id
      end

      # When there is no calculating task, this method returns true.
      # If the returned value is true then a node should finilize and exit.
      def send_result
        sent_task_id = []
        while !result_empty?
          task_id, result = dequeue_result
          @logger.info("Send result: #{task_id}") { result.inspect }
          @result.write([:result, task_id, @node_number, result])
          sent_task_id << task_id
        end
        sent_task_id.empty? ? nil : sent_task_id
      end

      def queue_result(task_id, result)
        @result_queue.enq([task_id, result])
      end

      def dump_result_queue
        results = []
        while !result_empty?
          task_id, res = dequeue_result
          results << res
        end
        if results.size > 0
          Marshal.dump(results)
        else
          nil
        end
      end
    end
  end
end
