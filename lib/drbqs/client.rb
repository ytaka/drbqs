require 'drbqs/connection'
require 'drbqs/task_client'

module DRbQS

  class Client

    WAIT_NEW_TASK = 1
    PRIORITY_RESPOND = 10
    PRIORITY_CALCULATE = 0
    OUTPUT_NOT_SEND_RESULT = 'not_send_result'
    DEFAULT_LOG_FILE = 'drbqs_client.log'

    # :continue
    def initialize(access_uri, opts = {})
      @access_uri = access_uri
      @logger = DRbQS::Utils.create_logger(opts[:log_file] || DEFAULT_LOG_FILE, opts[:log_level])
      @connection = nil
      @task_client = nil
      @process_continue = opts[:continue]
      @signal_queue = Queue.new
    end

    def transfer_file
      until FileTransfer.empty?
        path = FileTransfer.dequeue
        unless @transfer.scp(path)
          raise "Can not send file: #{path}"
        end
      end
    end
    private :transfer_file

    def execute_task(marshal_obj, method_sym, args)
      obj = Marshal.load(marshal_obj)
      result = obj.__send__(method_sym, *args)
      transfer_file
      result
    end
    private :execute_task

    def connect
      obj = DRbObject.new_with_uri(@access_uri)
      @connection = ConnectionClient.new(obj[:message], @logger)
      node_id = @connection.get_id
      @task_client = TaskClient.new(node_id, obj[:queue], obj[:result], @logger)
      @transfer = obj[:transfer]
      if ary = @connection.get_initialization
        execute_task(*ary)
      end
    end

    def dump_not_send_result_to_file
      if data = @task_client.dump_result_queue
        path = OUTPUT_NOT_SEND_RESULT + Time.now.to_i.to_s + '.dat'
        open(path, 'w') { |f| f.print data }
      end
    end
    private :dump_not_send_result_to_file

    def output_error(err)
      if @logger
        @logger.error("Raise error in calculating thread: #{err.to_s}") { "\n" + err.backtrace.join("\n") }
      end
    end
    private :output_error

    def process_exit
      dump_not_send_result_to_file
      unless @process_continue
        Kernel.exit
      end
    end
    private :process_exit

    def execute_finalization
      if ary = @connection.get_finalization
        execute_task(*ary)
      end
    rescue => err
      output_error(err)
    end
    private :execute_finalization

    def send_error(err)
      output_error(err)
      @connection.send_node_error("#{err.to_s}\n#{err.backtrace.join("\n")}")
    end
    private :send_error

    def communicate_with_server
      @task_client.add_new_task
      case @connection.respond_signal
      when :exit
        return nil
      when :finalize
        execute_finalization
        return nil
      end
      @task_client.send_result
      until @signal_queue.empty?
        signal, obj = @signal_queue.pop
        case signal
        when :node_error
          send_error(obj)
          process_exit
        end
      end
      return true
    end
    private :communicate_with_server

    def calculate_task
      marshal_obj, method_sym, args = @task_client.dequeue_task
      @task_client.queue_result(execute_task(marshal_obj, method_sym, args))
    end
    private :calculate_task

    def thread_communicate
      Thread.new do
        begin
          loop do
            unless communicate_with_server
              break
            end
            sleep(WAIT_NEW_TASK)
          end
        rescue => err
          send_error(err)
        ensure
          process_exit
        end
      end
    end
    private :thread_communicate

    def thread_calculate
      Thread.new do
        begin
          loop do
            calculate_task
          end
        rescue => err
          @signal_queue.push([:node_error, err])
        end
      end
    end
    private :thread_calculate

    def set_signal_trap
      Signal.trap(:TERM) do
        process_exit
      end
    end

    def calculate(opts = {})
      set_signal_trap
      cn = thread_communicate
      exec = thread_calculate
      cn.priority = PRIORITY_RESPOND
      exec.priority = PRIORITY_CALCULATE
      cn.join
    end
  end

end
