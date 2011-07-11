require 'drbqs/node/connection'
require 'drbqs/node/task_client'
require 'drbqs/node/temporary'

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
      @config = DRbQS::Config.new
    end

    def transfer_file
      files = []
      until FileTransfer.empty?
        files << FileTransfer.dequeue
      end
      if files.size > 0
        unless @transfer.transfer(files)
          raise "Can not send file: #{files.join(", ")}"
        end
      end
    end
    private :transfer_file

    def execute_task(marshal_obj, method_sym, args)
      result = DRbQS::Task.execute_task(marshal_obj, method_sym, args)
      transfer_file
      DRbQS::Temporary.delete
      result
    end
    private :execute_task

    def node_data
      { :uri => @access_uri }
    end
    private :node_data

    def connect
      obj = DRbObject.new_with_uri(@access_uri)
      @connection = ConnectionClient.new(obj[:message], @logger)
      node_id = @connection.get_id
      @task_client = TaskClient.new(node_id, obj[:queue], obj[:result], @logger)
      @transfer = obj[:transfer]
      if ary = @connection.get_initialization
        execute_task(*ary)
      end
      @config.list.node.save(Process.pid, node_data)
    end

    def dump_not_send_result_to_file
      if data = @task_client.dump_result_queue
        path = OUTPUT_NOT_SEND_RESULT + Time.now.to_i.to_s + '.dat'
        open(path, 'w') { |f| f.print data }
      end
    end
    private :dump_not_send_result_to_file

    def output_error(err, mes)
      if @logger
        @logger.error("#{mes}: #{err.to_s}") { "\n" + err.backtrace.join("\n") }
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
      output_error(err, "On finalization")
    end
    private :execute_finalization

    def send_error(err, mes)
      output_error(err, mes)
      @connection.send_node_error("#{err.to_s}\n#{err.backtrace.join("\n")}")
    end
    private :send_error

    def communicate_with_server
      flag_finilize_exit = false
      @task_client.add_new_task
      case @connection.respond_signal
      when :exit
        return nil
      when :finalize
        flag_finilize_exit = true
      when :exit_after_task
        @task_client.set_exit_after_task
        @process_continue = nil
      end
      flag_finilize_exit = @task_client.send_result
      until @signal_queue.empty?
        signal, obj = @signal_queue.pop
        case signal
        when :node_error
          send_error(obj, "Communicating with server")
          process_exit
        end
      end
      if flag_finilize_exit
        execute_finalization
        return nil
      end
      true
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
              DRbQS::Temporary.delete_all
              @config.list.node.delete(Process.pid)
              break
            end
            sleep(WAIT_NEW_TASK)
          end
        rescue => err
          send_error(err, "Calculating thread")
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
