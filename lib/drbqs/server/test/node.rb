require 'drbqs/node/node'

module DRbQS
  module Test
    class Node < DRbQS::Node
      def initialize(log_level, transfer, queue)
        super(nil, :log_file => $stdout, :log_level => log_level)
        DRbQS::Transfer::Client.set(transfer.get_client(true)) if transfer
        @task_client = DRbQS::Node::TaskClient.new(nil, queue, nil, [DRbQS::Node::SAME_HOST_GROUP], 1)
        @special_task_number = 0
      end

      def server_on_same_host?
        true
      end

      def subdirectory_name(task_id)
        if task_id
          sprintf("T%08d", task_id)
        else
          sprintf("S%08d", (@special_task_number += 1))
        end
      end
      private :subdirectory_name

      def execute_task(task_id, marshal_obj, method_sym, args)
        DRbQS::Temporary.set_sub_directory(subdirectory_name(task_id))
        result = DRbQS::Task.execute_task(marshal_obj, method_sym, args)
        if files = DRbQS::Transfer.dequeue_all
          transfer_file(files)
        end
        if subdir = DRbQS::Temporary.subdirectory
          FileUtils.rm_r(subdir)
        end
        result
      end
      private :execute_task

      def calc
        if ary = @task_client.get_task
          task_id, marshal_obj, method_sym, args = ary
          result = execute_task(task_id, marshal_obj, method_sym, args)
          return [task_id, result]
        end
        nil
      end

      def finalize(finalization_task_ary)
        if finalization_task_ary
          finalization_task_ary.each do |task|
            args = task.simple_drb_args
            execute_task(nil, *args)
          end
        end
        clear_node_files
      end
    end
  end
end
