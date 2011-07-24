require 'drbqs/node/node'

module DRbQS
  module Test
    class Node < DRbQS::Node
      def initialize(log_level, transfer, queue)
        super(nil, :log_file => $stdout, :log_level => log_level)
        @transfer = transfer
        @task_client = DRbQS::Node::TaskClient.new(nil, queue, nil)
      end

      def server_on_same_host?
        true
      end

      def calc
        if ary = @task_client.get_task
          task_id, marshal_obj, method_sym, args = ary
          result = execute_task(marshal_obj, method_sym, args)
          return [task_id, result]
        end
        nil
      end

      def finalize(finalization_task)
        if finalization_task
          args = finalization_task.drb_args(nil)[1..-1]
          execute_task(*args)
        end
        clear_node_files
      end
    end
  end
end
