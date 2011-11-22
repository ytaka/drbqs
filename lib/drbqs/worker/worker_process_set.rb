require 'drbqs/worker/serialize'
require 'drbqs/worker/forked_process'
require 'drbqs/utility/temporary.rb'

module DRbQS
  class Worker
    READ_BYTE_SIZE = 10240

    class ProcessSet
      attr_reader :process

      def initialize(process_class = nil)
        @process_class = process_class || DRbQS::Worker::SimpleForkedProcess
        @process = {}
        @result = Queue.new
        @on_error = nil
        @on_result = nil
      end

      def on_error(&block)
        @on_error = block
      end

      def on_result(&block)
        @on_result = block
      end

      def process_create(key)
        io_r, io_w = IO.pipe('BINARY')
        io_r2, io_w2 = IO.pipe('BINARY')
        parent_pid = Process.pid
        pid = fork do
          $PROGRAM_NAME = "[worker:#{key.to_s}] for drbqs-node (PID #{parent_pid})"
          io_w.close
          io_r2.close
          worker = @process_class.new(io_r, io_w2)
          worker.start
        end
        @process[key] = {
          :pid => pid, :out => io_w, :in => io_r2,
          :unpacker => DRbQS::Worker::Serialize::Unpacker.new,
          :task => []
        }
      end
      private :process_create

      def get_process(key)
        if @process[key]
          @process[key]
        else
          process_create(key)
        end
      end
      private :get_process

      def create_process(*keys)
        keys.each do |key|
          get_process(key)
        end
      end

      # Return true if the process of +key+ exists.
      # @param [Symbol,nil] key Key of child process or nil.
      def exist?(key)
        @process[key]
      end

      def has_process?
        !@process.empty?
      end

      # Return true if the process of +key+ is calculating.
      def calculating?(key)
        @process[key] && !@process[key][:task].empty?
      end

      # Return true if the process +key+ does not calculate any tasks.
      def waiting?(key)
        !calculating?(key)
      end

      # Return keys of processes not calculating a task.
      def waiting_processes
        @process.keys.select do |key|
          @process[key][:task].empty?
        end
      end

      def all_processes
        @process.keys
      end

      def output_to_io(io, obj)
        io.print Serialize.dump(obj)
        io.flush
      end
      private :output_to_io

      def send_object(key, obj)
        if h = get_process(key)
          output_to_io(h[:out], obj)
          h
        else
          nil
        end
      end
      private :send_object

      # @param [Array] dumped_task_ary is [task_id, obj, method_name, args].
      def send_task(key, dumped_task_ary)
        if h = send_object(key, dumped_task_ary)
          if dumped_task_ary[0]
            h[:task] << dumped_task_ary[0]
          end
        else
          raise "Process #{key.inspect} does not exist."
        end
      end

      def prepare_to_exit(key = nil)
        if key
          if h = send_object(key, :prepare_to_exit)
            h[:exit] = true
          end
        else
          @process.each do |key, h|
            prepare_to_exit(key)
          end
        end
      end

      def delete_process(key)
        if h = get_process(key)
          Process.detach(h[:pid])
          output_to_io(h[:out], :exit)
        else
          nil
        end
      end
      private :delete_process

      # Read IOs and respond signals from chiled processes.
      # If there is no data from child processes then the method returns false.
      # Otherwise, true.
      # Types of signals are :result, :node_error, :finish_preparing_to_exit.
      #  - :result
      #    Execute callback set by DRbQS::Worker::ProcessSet#on_result.
      #  - :node_error
      #    Execute callback set by DRbQS::Worker::ProcessSet#on_error.
      #  - :finish_preparing_to_exit
      #    Send :exit signale to the process and delete from list of child processes.
      def respond_signal
        num = 0
        to_be_deleted = []
        @process.each do |key, h|
          if !h[:task].empty? || h[:exit]
            data = ''
            begin
              loop do
                data << h[:in].read_nonblock(READ_BYTE_SIZE)
              end
            rescue IO::WaitReadable
            rescue
              $stderr.puts "Stored data: " + data.inspect
              raise
            end
            if !data.empty?
              num += 1
              h[:unpacker].feed_each(data) do |ary|
                response_type, response = ary
                case response_type
                when :result
                  task_id, result = response
                  h[:task].delete(task_id)
                  if @on_result
                    @on_result.call(key, [task_id, result])
                  else
                    $stderr.puts "The instance of DRbQS::Worker::ProcessSet can not deal with results from child processes."
                  end
                when :node_error
                  if @on_error
                    @on_error.call(key, response)
                  else
                    $stderr.puts "The instance of DRbQS::Worker::ProcessSet can not deal with error from child processes."
                  end
                when :finish_preparing_to_exit
                  delete_process(key)
                  to_be_deleted << key
                end
              end
            end
          end
        end
        to_be_deleted.each do |key|
          @process.delete(key)
        end
        to_be_deleted.clear
        num > 0
      end

      def kill_all_processes
        @process.each do |key, h|
          Process.detach(h[:pid])
          Process.kill("KILL", h[:pid])
        end
        @process.clear
      end

      WAITALL_INTERVAL_TIME = 0.1

      def waitall(interval_time = nil)
        unless @process.all? { |key, h| h[:exit] }
          return nil
        end
        t = interval_time || WAITALL_INTERVAL_TIME
        until @process.empty?
          respond_signal
          Kernel.sleep(t)
        end
        until Process.waitall == []
          Kernel.sleep(t)
        end
        true
      end
    end
  end
end
