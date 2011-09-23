require 'drbqs/worker/serialize'
require 'drbqs/worker/forked_process'
require 'drbqs/utility/temporary.rb'

module DRbQS
  class Worker
    READ_BYTE_SIZE = 1024

    attr_reader :process

    def initialize
      @process = {}
      @result = Queue.new
    end

    def process_create(key)
      io_r, io_w = IO.pipe('BINARY')
      io_r2, io_w2 = IO.pipe('BINARY')
      pid = fork do
        io_w.close
        io_r2.close
        worker = ForkedProcess.new(io_r, io_w2)
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

    def exist?(key)
      @process[key]
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

    # @param [Array] dumped_task_ary is [id, obj, method_name, args].
    def send_task(key, dumped_task_ary)
      if h = send_object(key, dumped_task_ary)
        h[:task] << dumped_task_ary[0]
      else
        raise "Process #{key.inspect} does not exist."
      end
    end

    def send_task_to_waiting_process(dumped_task_ary)
      key_not_working = nil
      @process.each do |key, h|
        if h[:task].empty?
          key_not_working = key
        end
      end
      if key_not_working
        send_task(key_not_working, dumped_task_ary)
        key_not_working
      else
        nil
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

    def respond_signal(&block)
      if block_given?
        num = 0
        to_be_deleted = []
        @process.each do |key, h|
          if !h[:task].empty? || h[:exit]
            begin
              data = h[:in].read_nonblock(READ_BYTE_SIZE)
              h[:unpacker].feed_each(data) do |ary|
                num += 1
                response_type, response = ary
                case response_type
                when :result
                  h[:task].delete(response[:id])
                  yield(key, response_type, response)
                when :node_error
                  yield(key, response_type, response)
                when :finish_preparing_to_exit
                  delete_process(key)
                  to_be_deleted << key
                end
              end
            rescue IO::WaitReadable
            end
          end
        end
        to_be_deleted.each do |key|
          @process.delete(key)
        end
        to_be_deleted.clear
        num > 0
      else
        to_enum(:respond_signal)
      end
    end

    def kill_all_processes
      @process.each do |key, h|
        Process.detach(h[:pid])
        Process.kill("KILL", h[:pid])
      end
      @process.clear
    end

    WAITALL_INTERVAL_TIME = 0.1

    def waitall
      unless @process.empty?
        return nil
      end
      until Process.waitall == []
        sleep(WAITALL_INTERVAL_TIME)
      end
      true
    end
  end
end
