module DRbQS
  class Node
    class TaskClient
      attr_reader :node_number, :calculating_task, :group

      def initialize(node_number, queue, result, group, logger = DRbQS::Misc::LoggerDummy.new)
        @node_number = node_number
        @queue = queue
        @result = result
        @calculating_task = []
        @exit_after_task = nil
        @task_queue = Queue.new
        @result_queue = Queue.new
        @group = group || []
        @logger = logger
      end

      def calculating?
        !@calculating_task.empty?
      end

      def waiting?
        !calculating?
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
        @calculating_task << ary[0]
        @task_queue.enq(ary)
      end

      def dequeue_task
        @task_queue.deq
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

      def set_exit_after_task
        @exit_after_task = true
      end

      def add_new_task
        if waiting? && !@exit_after_task && (ary = get_task)
          task_id = ary[0]
          @logger.info("Send accept signal: node #{@node_number} caluclating #{task_id}")
          @result.write([:accept, task_id, @node_number])
          queue_task(ary)
          return true
        end
        nil
      end

      # If the method return true, a node should finilize and exit.
      def send_result
        if !result_empty?
          result = dequeue_result
          @logger.info("Send result: #{@calculating_task[0]}") { result.inspect }
          @result.write([:result, @calculating_task[0], @node_number, result])
          @calculating_task.delete_at(0)
        end
        waiting? && @exit_after_task
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
end
