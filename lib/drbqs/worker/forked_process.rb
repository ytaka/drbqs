module DRbQS
  class Worker
    class SimpleForkedProcess
      def initialize(io_r, io_w)
        @io_r = io_r
        @io_w = io_w
        @queue = []
        @special_task_number = 0
      end

      def calculate(marshal_obj, method_sym, args)
        DRbQS::Task.execute_task(marshal_obj, method_sym, args)
      end

      def send_response(obj)
        @io_w.print DRbQS::Worker::Serialize.dump(obj)
        @io_w.flush
      end
      private :send_response

      def handle_task(obj)
        task_id, marshal_obj, method_sym, args = obj
        begin
          res = calculate(marshal_obj, method_sym, args)
          if task_id
            send_response([:result, [task_id, res]])
          end
        rescue => err
          send_response([:node_error, err])
        end
      end
      private :handle_task

      def start
        unpacker = DRbQS::Worker::Serialize::Unpacker.new
        loop do
          if @queue.empty?
            begin
              chunk = @io_r.readpartial(READ_BYTE_SIZE)
              unpacker.feed_each(chunk) do |ary|
                @queue << ary
              end
            rescue EOFError
              break
            end
          else
            obj = @queue.shift
            case obj
            when Array
              handle_task(obj)
            when :prepare_to_exit
              send_response([:finish_preparing_to_exit])
            when :exit
              break
            else
              send_response([:node_error, "Invalid object from server."])
            end  
          end
        end
      end
    end

    class ForkedProcess < DRbQS::Worker::SimpleForkedProcess
      def calculate(marshal_obj, method_sym, args)
        result = super(marshal_obj, method_sym, args)
        transfer_files = DRbQS::Transfer.dequeue_all
        { :result => result, :transfer => transfer_files }
      end

      def subdirectory_name(task_id)
        if task_id
          sprintf("T%08d", task_id)
        else
          sprintf("S%08d", (@special_task_number += 1))
        end
      end
      private :subdirectory_name

      def handle_task(obj)
        task_id, marshal_obj, method_sym, args = obj
        DRbQS::Temporary.set_sub_directory(subdirectory_name(task_id))
        begin
          result_hash = calculate(marshal_obj, method_sym, args)
          # If task_id is nil then the task is initialization or finalization.
          # So we do not return results.
          if task_id
            if subdir = DRbQS::Temporary.subdirectory
              result_hash[:tmp] = subdir
            end
            result_hash[:id] = task_id
            send_response([:result, [task_id, result_hash]])
          end
        rescue => err
          send_response([:node_error, err])
        end
      end
      private :handle_task
    end
  end
end
