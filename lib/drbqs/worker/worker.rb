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

    def send_object(key, obj, detach = nil)
      if h = get_process(key)
        Process.detach(h[:pid]) if detach
        h[:out].print Serialize.dump(obj)
        h[:out].flush
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

    def each_response(&block)
      @process.each do |key, h|
        unless h[:task].empty?
          begin
            data = h[:in].read_nonblock(READ_BYTE_SIZE)
            h[:unpacker].feed_each(data) do |ary|
              task_num, response = ary
              h[:task].delete(task_num)
              yield(key, response)
            end
          rescue IO::WaitReadable
          end
        end
      end
    end

    def kill_process(key)
      if send_object(key, nil, true)
        @process.delete(key)
      end
    end

    def kill_all_processes(force = nil)
      if force
        @process.each do |key, h|
          Process.detach(h[:pid])
          Process.kill("KILL", h[:pid])
        end
        @process.clear
      else
        @process.keys.each do |key|
          kill_process(key)
        end
      end
    end

    WAITALL_INTERVAL_TIME = 0.1

    def waitall
      unless @process.empty?
        raise "Process will not exit."
      end
      until Process.waitall == []
        sleep(WAITALL_INTERVAL_TIME)
      end
    end
  end
end
