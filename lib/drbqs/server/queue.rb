require 'drbqs/server/history'

module DRbQS

  class Server
    class Queue
      attr_reader :calculating, :history

      def initialize(queue, result, logger = DRbQS::LoggerDummy.new)
        @queue = queue
        @result = result
        @task_id = 0
        @cache = {}
        @calculating = Hash.new { |hash, key| hash[key] = Array.new }
        @history = DRbQS::Server::TaskHistory.new
        @logger = logger
      end

      def queue_task(task_id)
        @queue.write(@cache[task_id].drb_args(task_id))
      end
      private :queue_task

      # &hook take two arguments: a DRbQS::Server::Queue object and a result of task.
      # Return task ID (for debug).
      def add(task)
        @task_id += 1
        @logger.info("New task: #{@task_id}")
        @cache[@task_id] = task
        queue_task(@task_id)
        @history.set(@task_id, :add)
        @task_id
      end

      def get_accept_signal
        count = 0
        begin
          loop do
            sym, task_id, node_id = @result.take([:accept, Fixnum, Fixnum], 0)
            count += 1
            @calculating[node_id] << task_id
            @history.set(task_id, :calculate, node_id)
            @logger.info("Accept: task #{task_id} by node #{node_id}.")
          end
        rescue Rinda::RequestExpiredError
          @logger.debug("Accept: #{count} signals.")
        end
        count
      end

      def requeue_for_deleted_node_id(deleted)
        deleted.each do |node_id|
          if task_id_ary = @calculating[node_id]
            task_id_ary.each do |task_id|
              queue_task(task_id)
              @history.set(task_id, :requeue)
              @logger.info("Requeue: task #{task_id}.")
            end
            @calculating.delete(node_id)
          end
        end
      end

      def delete_task_id(node_id, task_id)
        unless @calculating[node_id].delete(task_id)
          @logger.error("Task #{task_id} does not exist in list of calculating tasks.")
        end
        if ary = @calculating.find { |k, v| v.include?(task_id) }
          @logger.error("Node #{ary[0]} is calculating task #{task_id}, too.")
        end
      end
      private :delete_task_id

      def exec_task_hook(main_server, task_id, result)
        if task = @cache.delete(task_id)
          if task.exec_hook(main_server, result)
            @history.set(task_id, :hook)
          end
          true
        else
          @logger.error("Task #{task_id} is not cached.")
          false
        end
      end

      def get_result(main_server)
        count = 0
        begin
          loop do
            get_accept_signal
            sym, task_id, node_id, result = @result.take([:result, Fixnum, Fixnum, nil], 0)
            count += 1
            @history.set(task_id, :result, node_id)
            @logger.info("Get: result of #{task_id} from node #{node_id}.")
            delete_task_id(node_id, task_id)
            exec_task_hook(main_server, task_id, result)
          end
        rescue Rinda::RequestExpiredError
          @logger.debug("Get: #{count} results.")
        end
        count
      end

      def calculating_task_number
        @calculating.inject(0) { |s, key_val| s + key_val[1].size }
      end

      def stocked_task_number
        @cache.size - calculating_task_number
      end

      # If queue is empty, that is, there is no tasks to calculate next,
      # this method returns true. Otherwise, false.
      # Even if there are calculating tasks,
      # the method can return true.
      def empty?
        stocked_task_number == 0
      end

      # If there are no tasks in queue and calculating,
      # return true. Otherwise, false.
      def finished?
        @cache.size == 0
      end

      def all_logs
        @history.log_strings
      end
    end

  end
end
