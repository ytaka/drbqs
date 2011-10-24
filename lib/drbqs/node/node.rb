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
    WAIT_NEW_TASK_TIME = 1
    SAME_HOST_GROUP = :local

    # @param [String] acces_uri Set the uri of server
    # @param [Hash] opts Options of a node
    # @option opts [Fixnum] :process Number of worker processes
    # @option opts [Array] :group An array of group symbols
    # @option opts [Fixnum] :sleep_time Time interval during sleep of the node
    # @option opts [String] :max_loadavg Note that this optiono is experimental
    def initialize(access_uri, opts = {})
      @access_uri = access_uri
      @logger = DRbQS::Misc.create_logger(opts[:log_file] || DEFAULT_LOG_FILE, opts[:log_level])
      @connection = nil
      @task_client = nil
      @worker_number = opts[:process] || 1
      @state = DRbQS::Node::State.new(:wait, @worker_number, :max_loadavg => opts[:max_loadavg], :sleep_time => opts[:sleep_time])
      @group = opts[:group] || []
      @signal_to_server_queue = Queue.new
      @config = DRbQS::Config.new
      @special_task_number = 0
      @worker = DRbQS::Worker::ProcessSet.new(DRbQS::Worker::ForkedProcess)
      @worker.on_result do |proc_key, res|
        task_id, h = res
        queue_result(task_id, h)
      end
      @worker.on_error do |proc_key, res|
        @signal_to_server_queue.push([:node_error, res])
      end
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

    def queue_result(task_id, result_hash)
      if files = result_hash[:transfer]
        transfer_file(files)
      end
      if subdir = result_hash[:tmp]
        FileUtils.rm_r(result_hash[:tmp])
      end
      @task_client.queue_result(task_id, result_hash[:result])
    end
    private :queue_result

    def node_data
      { :uri => @access_uri }
    end
    private :node_data

    # @param [Array] task_ary An array from @connection.get_initialization or @connection.get_finalization.
    def send_special_task_ary_to_all_workers(task_ary)
      task_ary.each do |ary|
        ary_to_send = [nil] + ary
        @state.each_worker_id do |wid|
          @worker.send_task(wid, ary_to_send)
        end
      end
    end
    private :send_special_task_ary_to_all_workers

    # Connect to the server and finish initialization of the node.
    def connect
      obj = DRbObject.new_with_uri(@access_uri)
      @server_key = obj[:key]
      @connection = DRbQS::Node::Connection.new(obj[:message], @logger)
      set_node_group_for_task
      @task_client = DRbQS::Node::TaskClient.new(@connection.node_number, obj[:queue], obj[:result],
                                                 @group, @logger)
      DRbQS::Transfer::Client.set(obj[:transfer].get_client(server_on_same_host?)) if obj[:transfer]
      @state.each_worker_id do |wid|
        @worker.create_process(wid)
      end
      if ary_initialization = @connection.get_initialization
        send_special_task_ary_to_all_workers(ary_initialization)
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
      @worker.waitall
      if ary_finalization = @connection.get_finalization
        send_special_task_ary_to_all_workers(ary_finalization)
      end
    rescue => err
      output_error(err, "On finalization")
    end
    private :execute_finalization

    def send_error(err, mes)
      output_error(err, mes)
      begin
        @connection.send_node_error("#{err.to_s}\n#{err.backtrace.join("\n")}")
      rescue
      end
    end
    private :send_error

    def get_new_task
      if @state.request? && (obtained_task_id = @task_client.add_new_task(@state.request_task_number))
        return obtained_task_id
      end
      nil
    end
    private :get_new_task

    def send_result_to_server
      if sent_task_id = @task_client.send_result
        @state.set_finish_of_task(sent_task_id)
      end
    end
    private :send_result_to_server

    # Send signals from @signal_to_server_queue,
    # which stores errors of workers and signals to current process.
    # @return [Boolean] If some error signal is sent then this method returns true. Otherwise, nil.
    def send_signal
      flag_finalize_exit = nil
      until @signal_to_server_queue.empty?
        signal, obj = @signal_to_server_queue.pop
        case signal
        when :node_error
          send_error(obj, "Communicating with server")
          dump_not_send_result_to_file
          flag_finalize_exit = true
        when :signal_kill
          flag_finalize_exit = true
        else
          raise "Not implemented"
        end
      end
      flag_finalize_exit
    end
    private :send_signal

    # If the method returns true, the node finishes.
    def process_signal_for_server
      flag_finalize_exit = send_signal
      case @connection.respond_signal
      when :wake
        @state.wakeup_sleeping_worker
      when :sleep
        @state.change_to_sleep
      when :exit
        return nil
      when :finalize
        flag_finalize_exit = true
      when :exit_after_task
        @state.set_exit_after_task
      end
      if flag_finalize_exit
        execute_finalization
        return nil
      end
      @state.wakeup_automatically_for_unbusy_system
      true
    end
    private :process_signal_for_server

    # Dequeue tasks from @task_client and send them to worker processes.
    def send_task_to_worker
      wids = @state.waiting_worker_id
      wids.each do |wid|
        if ary = @task_client.dequeue_task
          @state.set_calculating_task(wid, ary[0])
          @worker.send_task(wid, ary)
        else
          break
        end
      end
    end
    private :send_task_to_worker

    def clear_node_files
      DRbQS::Temporary.delete_all
      @config.list.node.delete(Process.pid)
    end
    private :clear_node_files

    def wait_interval_of_connection
      Kernel.sleep(INTERVAL_TIME_DEFAULT)
    end
    private :wait_interval_of_connection

    def set_signal_trap
      Signal.trap(:TERM) do
        @signal_to_server_queue.push([:signal_kill])
      end
    end

    MAX_WORKER_WAIT_TIME = 3
    WORKER_WAIT_INTERVAL = 0.1

    def respond_worker_signal
      @worker.respond_signal
    end
    private :respond_worker_signal

    def wait_process_finish
      @worker.prepare_to_exit
      total_wait_time = 0.0
      loop do
        respond_worker_signal
        if !@worker.has_process?
          break
        elsif total_wait_time > MAX_WORKER_WAIT_TIME
          # Kill worker processes forcibly.
          @worker.kill_all_processes
          break
        end
        sleep(WORKER_WAIT_INTERVAL)
        total_wait_time += WORKER_WAIT_INTERVAL
      end
      send_result_to_server
    end
    private :wait_process_finish

    def calculate(opts = {})
      set_signal_trap
      begin
        server_has_no_task = nil
        loop do
          send_result_to_server
          unless process_signal_for_server
            break
          end
          if @state.change_to_sleep_for_busy_system
            @logger.info("Sleep because system is busy.")
          end
          if server_has_no_task && (t = server_has_no_task + WAIT_NEW_TASK_TIME - Time.now) > 0
            sleep(t)
            server_has_no_task = nil
          end
          if get_new_task
            send_task_to_worker
          elsif @state.ready_to_exit_after_task? && @task_client.result_empty?
            execute_finalization
            break
          elsif @state.request?
            server_has_no_task = Time.now
          end
          unless respond_worker_signal
            wait_interval_of_connection
          end
        end
      rescue => err
        send_error(err, "Node error occurs.")
        @worker.kill_all_processes
      end
      wait_process_finish
      clear_node_files
    end
  end
end
