module DRbQS
  class Worker
    class ForkedProcess
      def initialize(io_r, io_w)
        @io_r = io_r
        @io_w = io_w
        @queue = Queue.new
        @special_task_number = 0
      end

      def calculate(marshal_obj, method_sym, args)
        result = DRbQS::Task.execute_task(marshal_obj, method_sym, args)
        transfer_files = DRbQS::Transfer.dequeue_all
        { :result => result, :transfer => transfer_files }
      end

      def send_response(obj)
        @io_w.print DRbQS::Worker::Serialize.dump(obj)
        @io_w.flush
      end
      private :send_response

      def subdirectory_name(task_id)
        if task_id
          sprintf("T%08d", task_id)
        else
          sprintf("S%08d", (@special_task_number += 1))
        end
      end
      private :subdirectory_name

      def start
        Thread.abort_on_exception = true
        th = Thread.new do
          unpacker = DRbQS::Worker::Serialize::Unpacker.new
          loop do
            begin
              chunk = @io_r.readpartial(READ_BYTE_SIZE)
              unpacker.feed_each(chunk) do |ary|
                @queue.push(ary)
              end
            rescue EOFError
              @queue.push(nil)
              break
            end
          end
        end

        loop do
          obj = @queue.pop
          case obj
          when Array
            task_id, marshal_obj, method_sym, args = obj
            DRbQS::Temporary.set_sub_directory(subdirectory_name(task_id))
            begin
              result_hash = calculate(marshal_obj, method_sym, args)
              if subdir = DRbQS::Temporary.subdirectory
                result_hash[:tmp] = subdir
              end
              result_hash[:id] = task_id
              send_response([:result, result_hash])
            rescue => err
              send_response([:node_error, err])
            end
          when :prepare_to_exit
            send_response([:finish_preparing_to_exit])
            @queue.pop          # :exit
            break
          end
        end
      end
    end
  end
end
