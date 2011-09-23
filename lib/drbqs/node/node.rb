require 'drbqs/task/task'
require 'drbqs/utility/temporary'
require 'drbqs/utility/transfer/transfer_client'
require 'drbqs/node/connection'
require 'drbqs/node/task_client'
require 'drbqs/node/state'
require 'drbqs/worker/worker'

module DRbQS

  class Node

    PRIORITY_RESPOND = 10
    PRIORITY_CALCULATE = 0
    OUTPUT_NOT_SEND_RESULT = 'not_send_result'
    DEFAULT_LOG_FILE = 'drbqs_client.log'
    INTERVAL_TIME_DEFAULT = 0.1
    SAME_HOST_GROUP = :local

    # @param [String] acces_uri Set the uri of server
    # @param [Hash] opts Options of a node
    # @option opts [Array] :group An array of group symbols
    # @option opts [Boolean] :continue If we set true then the node process does not exit
    # @option opts [Fixnum] :sleep_time Time interval during sleep of the node
    # @option opts [String] :max_loadavg Note that this optiono is experimental
    def initialize(access_uri, opts = {})
      @access_uri = access_uri
      @logger = DRbQS::Misc.create_logger(opts[:log_file] || DEFAULT_LOG_FILE, opts[:log_level])
      @connection = nil
      @task_client = nil
      @state = DRbQS::Node::State.new(:wait, :max_loadavg => opts[:max_loadavg], :sleep_time => opts[:sleep_time])
      @process_continue = opts[:continue]
      @group = opts[:group] || []
      @signal_queue = Queue.new
      @config = DRbQS::Config.new
      @special_task_number = 0
      @worker = DRbQS::Worker.new
    end

    def transfer_file(files)
      begin
        DRbQS::Transfer::Client.transfer_to_server(files)
      rescue Exception => err
        @logger.error("Fail to transfer files.") do
          "#{err.to_s} (#{err.class})\n#{err.backtrace.join("\n")}"
        end
        raise
      end
    end
    private :transfer_file

    def queue_result(result_hash)
      if files = result_hash[:transfer]
        transfer_file(files)
      end
      if subdir = result_hash[:tmp]
        FileUtils.rm_r(result_hash[:tmp])
      end
      @task_client.queue_result(result_hash[:result])
    end
    private :queue_result

    def node_data
      { :uri => @access_uri }
    end
    private :node_data

    def worker_key
      @task_client.node_number
    end
    private :worker_key

    # Connect to the server and finish initialization of the node.
    def connect
      obj = DRbObject.new_with_uri(@access_uri)
      @server_key = obj[:key]
      @connection = DRbQS::Node::Connection.new(obj[:message], @logger)
      set_node_group_for_task
      @task_client = DRbQS::Node::TaskClient.new(@connection.node_number, obj[:queue], obj[:result],
                                                 @group, @logger)
      DRbQS::Transfer::Client.set(obj[:transfer].get_client(server_on_same_host?)) if obj[:transfer]
      @worker.create_process(worker_key)
      if ary_initialization = @connection.get_initialization
        ary_initialization.each do |ary|
          @worker.send_task(worker_key, [nil] + ary)
        end
      end
      @config.list.node.save(Process.pid, node_data)
    end

    # This method must be executed after @connection is set.
    def set_node_group_for_task
      if server_on_same_host?
        @group << DRbQS::Node::SAME_HOST_GROUP
      end
    end
    private :set_node_group_for_task

    def server_on_same_host?
      @server_on_same_host ||
        (@server_on_same_host = @config.list.server.server_of_key_exist?(@access_uri, @server_key))
    end

    def dump_not_send_result_to_file
      if data = @task_client.dump_result_queue
        path = OUTPUT_NOT_SEND_RESULT + Time.now.to_i.to_s + '.dat'
        open(path, 'w') { |f| f.print data }
      end
    end
    private :dump_not_send_result_to_file

    def output_error(err, mes)
      @logger.error("#{mes}: #{err.to_s}") { "\n" + err.backtrace.join("\n") }
    end
    private :output_error

    def execute_finalization
      if ary_finalization = @connection.get_finalization
        ary_finalization.each do |ary|
          @worker.send_task(worker_key, [nil] + ary)
        end
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

    def get_new_task
      if @state.request?
        if @state.change_to_sleep_for_busy_system
          @logger.info("Sleep because system is busy.")
        elsif @task_client.add_new_task
          @state.change_to_calculate
        end
      end
    end
    private :get_new_task

    def send_result
      flag_finilize_exit = @task_client.send_result
      if @state.calculate? && @task_client.waiting?
        @state.change_to_finish_calculating
      end
      flag_finilize_exit
    end
    private :send_result

    def send_signal
      flag_finilize_exit = nil
      until @signal_queue.empty?
        signal, obj = @signal_queue.pop
        case signal
        when :node_error
          send_error(obj, "Communicating with server")
          dump_not_send_result_to_file
          flag_finilize_exit = true
        when :signal_kill
          flag_finilize_exit = true
        else
          raise "Not implemented"
        end
      end
    end
    private :send_signal

    def process_signal
      case @connection.respond_signal
      when :wake
        @state.change_to_wait
      when :sleep
        @state.change_to_sleep
      when :exit
        return :exit
      when :finalize
        return :finalize
      when :exit_after_task
        @task_client.set_exit_after_task
        @process_continue = nil
      end
      nil
    end
    private :process_signal

    # If the method returns true, the node finishes.
    def communicate_with_server
      get_new_task
      sig = process_signal
      return nil if sig == :exit
      flag_finilize_exit = send_result || send_signal
      if sig == :finalize || flag_finilize_exit
        execute_finalization
        return nil
      end
      @state.wakeup_automatically_for_unbusy_system
      true
    end
    private :communicate_with_server

    def send_task
      if ary = @task_client.dequeue_task
        @worker.send_task(worker_key, ary)
        true
      else
        nil
      end
    end
    private :send_task

    def clear_node_files
      DRbQS::Temporary.delete_all
      @config.list.node.delete(Process.pid)
    end
    private :clear_node_files

    def wait_interval_of_connection
      sleep(INTERVAL_TIME_DEFAULT)
    end
    private :wait_interval_of_connection

    def set_signal_trap
      Signal.trap(:TERM) do
        @signal_queue.push([:signal_kill])
      end
    end

    MAX_WAIT_FINISH = 3
    WAIT_INTERVAL = 0.1

    def respond_signal
      @worker.respond_signal do |k, type, res|
        case type
        when :result
          queue_result(res)
        when :node_error
          @signal_queue.push([:node_error, res])
        end
      end
    end
    private :respond_signal

    def wait_process_finish
      @worker.prepare_to_exit
      total_wait_time = 0.0
      loop do
        respond_signal
        if @worker.process.empty? || total_wait_time > MAX_WAIT_FINISH
          break
        end
        sleep(WAIT_INTERVAL)
        total_wait_time += WAIT_INTERVAL
      end
    end
    private :wait_process_finish

    def calculate(opts = {})
      set_signal_trap
      begin
        loop do
          unless communicate_with_server
            break
          end
          send_task
          respond_signal
          wait_interval_of_connection
        end
      rescue => err
        send_error(err, "Node error occurs.")
      end
      wait_process_finish
      send_result
      clear_node_files
    end
  end
end
