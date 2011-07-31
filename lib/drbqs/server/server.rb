require 'drbqs/task/task'
require 'drbqs/server/transfer_setting'
require 'drbqs/server/check_alive'
require 'drbqs/server/message'
require 'drbqs/server/queue'
require 'drbqs/server/acl_file'
require 'drbqs/server/server_hook'

module DRbQS

  # When we set both empty_queue_hook and task_generator,
  # empty_queue_hook is prior to task_generator.
  class Server
    include DRbQS::Misc

    WAIT_TIME_NODE_EXIT = 3
    WAIT_TIME_NODE_FINALIZE = 10
    WAIT_TIME_NEW_RESULT = 1

    attr_reader :queue, :uri

    # :port
    #   Set the port of server.
    # :unix
    #   Set the path of unix domain socket.
    #   If :port is specified, :port is preceded.
    # :acl
    #   Set the ACL instance.
    # :log_file
    #   Set the path of log files.
    # :log_level
    #   Set the level of logging.
    # :check_alive
    #   Set the time interval of checking alive nodes.
    # :finish_exit
    #   Exit programs in finish_hook.
    # :shutdown_unused_nodes
    #   Shutdown unused nodes.
    # :signal_trap
    #   Set trapping signal.
    # :sftp_user
    #   Set user of sftp.
    # :sftp_host
    #   Set host of sftp.
    # :file_directory
    #   Set the setting of file directory.
    def initialize(opts = {})
      @uri = DRbQS::Misc.create_uri(opts)
      @acl = acl_init(opts[:acl])
      @key = DRbQS::Misc.random_key + sprintf("_%d", Time.now.to_i)
      @ts = {
        :message => Rinda::TupleSpace.new,
        :queue => Rinda::TupleSpace.new,
        :result => Rinda::TupleSpace.new,
        :key => @key,
        :transfer => nil
      }
      @logger = DRbQS::Misc.create_logger(opts[:log_file], opts[:log_level])
      @message = DRbQS::Server::Message.new(@ts[:message], @logger)
      @queue= DRbQS::Server::Queue.new(@ts[:queue], @ts[:result], @logger)
      @check_alive = DRbQS::Server::CheckAlive.new(opts[:check_alive])
      @task_generator = []
      hook_init(opts[:finish_exit], opts[:shutdown_unused_nodes])
      set_signal_trap if opts[:signal_trap]
      @finalization_task = nil
      @data_storage = []
      @transfer_setting = DRbQS::Server::TransferSetting.new(opts[:sftp_host], opts[:sftp_user], opts[:file_directory])
      @config = DRbQS::Config.new
    end

    def transfer_directory
      @transfer_setting.prepared_directory
    end

    def acl_init(acl_arg)
      case acl_arg
      when Array
        ACL.new(acl_arg)
      when String
        DRbQS::Server::ACLFile.load(acl_arg)
      else
        nil
      end
    end
    private :acl_init

    def hook_init(finish_exit, shutdown_nodes)
      @hook = DRbQS::Server::Hook.new
      @hook.set_finish_exit { self.exit } if finish_exit
      @hook.set_shutdown_unused_nodes { shutdown_unused_nodes } if shutdown_nodes
    end
    private :hook_init

    def server_data
      { :pid => Process.pid, :key => @key }
    end
    private :server_data

    def start
      set_file_transfer(nil)
      DRb.install_acl(@acl) if @acl
      DRb.start_service(@uri, @ts)
      @config.list.server.save(@uri, server_data)
      @logger.info("Start DRb service") { @uri }
    end

    def check_connection(force = nil)
      if force || @check_alive.significant_interval?
        @logger.info("Check connections.")
        deleted_node_ids = @message.check_connection
        @queue.requeue_for_deleted_node_id(deleted_node_ids)
        @check_alive.set_checking
      end
    end
    private :check_connection

    def add_task_generator(task_generator)
      @task_generator << task_generator
    end

    # If current task generator waits for finish of created tasks,
    # this method returns true.
    def generator_waiting?
      @task_generator.size > 0 && @task_generator[0].waiting?
    end
    private :generator_waiting?

    def add_tasks_from_generator
      if @task_generator.size > 0 && @queue.empty?
        if tasks = @task_generator[0].new_tasks
          tasks.each { |t| @queue.add(t) }
          @logger.info("Generator add #{tasks.size} tasks.")
        else
          @task_generator.delete_at(0)
          @logger.info("Generator creates all tasks and then has been deleted.")
          if @task_generator.size > 0
            first_task_generator_init
            add_tasks_from_generator
          end
        end
      end
    end
    private :add_tasks_from_generator

    def all_tasks_assigned?
      @task_generator.empty? && @queue.empty?
    end
    private :all_tasks_assigned?

    def set_initialization_task(task)
      @message.set_initialization(task)
    end

    def set_finalization_task(task)
      @finalization_task = task
      @message.set_finalization(@finalization_task)
    end

    # +key+ is :empty_queue, :process_data, or :finish_exit.
    # &block takes self as an argument.
    def add_hook(key, name = nil, &block)
      if key == :process_data
        if @hook.number_of_hook(:process_data) != 0
          raise "Hook :process_data has already set."
        end
      end
      @hook.add(key, name, &block)
    end

    def delete_hook(key, name = nil)
      @hook.delete(key, name)
    end

    def exec_empty_queue_hook
      @hook.exec(:empty_queue, self) do |name|
        if @queue.empty?
          @logger.info("Execute empty queue hook: #{name}.")
          true
        else
          false
        end
      end
    end
    private :exec_empty_queue_hook

    def exec_finish_hook
      @hook.exec(:finish, self) do |name|
        if !generator_waiting? && @queue.finished?
          @logger.info("Execute finish hook: #{name}.")
          true
        else
          false
        end
      end
    end
    private :exec_finish_hook
    
    def exec_task_assigned_hook
      @hook.exec(:task_assigned, self) do |name|
        if all_tasks_assigned?
          @logger.info("Execute task assigned hook: #{name}.")
          true
        else
          false
        end
      end
    end
    private :exec_task_assigned_hook

    def exec_process_data_hook
      if @data_storage.size > 0
        while data = @data_storage.shift
          process_data(data)
        end
      end
    end
    private :exec_process_data_hook

    def exec_hook
      exec_process_data_hook
      exec_empty_queue_hook
      if !generator_waiting? || @queue.finished?
        add_tasks_from_generator
      end
      exec_finish_hook
      exec_task_assigned_hook
    end
    private :exec_hook

    def shutdown_unused_nodes
      @message.shutdown_unused_nodes(@queue.calculating_nodes)
    end
    private :shutdown_unused_nodes

    def exit
      if @finalization_task
        @message.send_finalization
        wait_time = WAIT_TIME_NODE_FINALIZE
      else
        @message.send_exit
        wait_time = WAIT_TIME_NODE_EXIT
      end
      until @message.node_not_exist?
        sleep(wait_time)
        check_connection(true)
      end
      @logger.info("History of tasks") { "\n" + @queue.all_logs }
      @config.list.server.delete(@uri)
      Kernel.exit
    end

    def set_signal_trap
      Signal.trap(:TERM) do
        self.exit
      end
    end

    def set_file_transfer(directory, opts = {})
      if @transfer_setting.setup_server(directory, opts)
        @ts[:transfer] = @transfer_setting
        @logger.info("File transfer") { @transfer_setting.information }
      end
    end

    # Set *args to data storage, which must be string objects.
    # The data is processed by hook of :process_data.
    def set_data(*args)
      args.each do |s|
        if String === s
          @data_storage << s
        else
          @logger.error("Invalid data type\n#{s.inspect}")
        end
      end
    end

    def process_data(data)
      @hook.exec(:process_data, self, data)
    rescue => err
      @logger.error("Error in processing data.") do
        "#{err.to_s} (#{err.class})\n#{err.backtrace.join("\n")}"
      end
    end
    private :process_data

    def send_status_for_request
      messages = @queue.calculating_task_message
      s = ''
      @message.each_node_history do|node_id, events|
        if events.size == 0
          s << "Empty history of node #{node_id}\n"
        else
          connect = events[0]
          s << sprintf("%4d %s\t", node_id, connect[2])
          if events.size > 1
            s << "start:#{time_to_history_string2(connect[0])}"
            events[1..-1].each do |t, key|
              s << ", #{key}: #{time_to_history_string2(t)}"
            end
            s << "\n"
          else
            task_ids = @queue.calculating[node_id].to_a
            s << "task: "
            s << messages[node_id].map do |task_id, mes|
              calc_task = task_id.to_s
              calc_task << ": " << mes.to_s if mes
              calc_task
            end.join(', ')
            s << " (#{time_to_history_string2(connect[0])})\n"
          end
        end
      end
      s << "  none\n" if s.size == 0
      s = "Nodes:\n" << s
      s << "Server:\n"
      s << "  calculating tasks: #{@queue.calculating_task_number}\n"
      s << "  finished tasks   : #{@queue.finished_task_number}\n"
      s << "  stocked tasks    : #{@queue.stocked_task_number}\n"
      s << "  task generator   : #{@task_generator.size}"
      @message.send_status(s)
    end
    private :send_status_for_request

    def check_message
      while mes_arg = @message.get_message
        mes, arg = mes_arg
        case mes
        when :new_data
          set_data(arg)
        when :exit_server
          self.exit
        when :request_status
          send_status_for_request
        when :request_history
          @message.send_history(@queue.all_logs)
        when :exit_after_task
          @message.send_exit_after_task(arg)
        when :wake_node
          @message.send_wake(arg)
        when :sleep_node
          @message.send_sleep(arg)
        when :node_error
          @queue.get_accept_signal
          @queue.requeue_for_deleted_node_id([arg])
        end
      end
    end
    private :check_message

    def first_task_generator_init
      @task_generator[0].init if @task_generator[0]
    end
    private :first_task_generator_init

    def wait
      first_task_generator_init
      loop do
        check_message
        check_connection
        count_results = @queue.get_result(self)
        exec_hook
        @logger.debug("Calculating tasks: #{@queue.calculating_task_number}")
        if count_results <= 1
          sleep(WAIT_TIME_NEW_RESULT)
        end
      end
    end
  end
end
