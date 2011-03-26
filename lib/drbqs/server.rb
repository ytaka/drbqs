require 'drbqs/message'
require 'drbqs/queue'
require 'drbqs/acl_file'
require 'drbqs/server_hook'

module DRbQS
  class CheckAlive
    DEFAULT_INTERVAL_TIME = 300

    def initialize(interval)
      @interval = interval || DEFAULT_INTERVAL_TIME
      if !(Numeric === @interval) || @interval < 0
        raise ArgumentError, "Invalid interval time."
      end
      @last = Time.now
    end

    def significant_interval?
      (Time.now - @last) >= @interval
    end

    def set_checking
      @last = Time.now
    end
  end

  # When we set both empty_queue_hook and task_generator,
  # empty_queue_hook is prior to task_generator.
  class Server
    WAIT_TIME_NODE_EXIT = 3
    WAIT_TIME_NODE_FINALIZE = 10
    WAIT_TIME_NEW_RESULT = 1

    attr_reader :queue

    # :port
    #   Set the port of server.
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
    # :signal_trap
    #   Set trapping signal.
    # :scp_user
    #   Set user of scp.
    # :scp_host
    #   Set host of scp.
    # :file_directory
    #   Set the setting of file directory.
    def initialize(opts = {})
      @port = opts[:port] || ROOT_DEFAULT_PORT
      @acl = acl_init(opts[:acl])
      @ts = {
        :message => Rinda::TupleSpace.new,
        :queue => Rinda::TupleSpace.new,
        :result => Rinda::TupleSpace.new,
        :transfer => nil
      }
      @logger = DRbQS::Utils.create_logger(opts[:log_file], opts[:log_level])
      @message = MessageServer.new(@ts[:message], @logger)
      @queue= QueueServer.new(@ts[:queue], @ts[:result], @logger)
      @check_alive = CheckAlive.new(opts[:check_alive])
      @task_generator = []
      hook_init(opts[:finish_exit])
      set_signal_trap if opts[:signal_trap]
      @finalization_task = nil
      @transfer_setting = get_transfer_setting(opts[:scp_host], opts[:scp_user], opts[:file_directory])
    end

    def get_transfer_setting(host, user, directory)
      setting = { :directory => directory, :user => user, :host => host, :set => true }
      if host || user || directory
        setting[:set] = true
      end
      setting
    end
    private :get_transfer_setting

    def acl_init(acl_arg)
      case acl_arg
      when Array
        ACL.new(acl_arg)
      when String
        ACLFile.load(acl_arg)
      else
        nil
      end
    end
    private :acl_init

    def hook_init(finish_exit)
      @hook = DRbQS::ServerHook.new
      @hook.set_finish_exit { self.exit } if finish_exit
    end
    private :hook_init

    def start
      if @transfer_setting[:set] && @transfer_setting[:directory] && !@ts[:transfer]
        set_file_transfer(@transfer_setting[:directory])
      end
      DRb.install_acl(@acl) if @acl
      uri = "druby://:#{@port}"
      DRb.start_service(uri, @ts)
      @logger.info("Start DRb service") { uri } if @logger
    end

    def check_connection(force = nil)
      if force || @check_alive.significant_interval?
        @logger.info("Check connections.") if @logger
        deleted_node_ids = @message.check_connection
        @queue.requeue_for_deleted_node_id(deleted_node_ids)
        @check_alive.set_checking
      end
    end
    private :check_connection

    def add_task_generator(task_generator)
      @task_generator << task_generator
    end

    def add_tasks_from_generator
      if @task_generator.size > 0 && @queue.empty?
        if tasks = @task_generator[0].new_tasks
          tasks.each { |t| @queue.add(t) }
          @logger.info("Generator add #{tasks.size} tasks.") if @logger
        else
          @task_generator.delete_at(0)
          @logger.info("Generator creates all tasks and then has been deleted.") if @logger
          if @task_generator.size > 0
            add_tasks_from_generator
          end
        end
      end
    end
    private :add_tasks_from_generator

    def set_initialization_task(task)
      @message.set_initialization(task)
    end

    def set_finalization_task(task)
      @finalization_task = task
    end

    # +key+ is :empty_queue or :finish_exit.
    # &block takes self as an argument.
    def add_hook(key, name = nil, &block)
      @hook.add(key, name, &block)
    end

    def delete_hook(key, name = nil)
      @hook.delete(key, name)
    end

    def exec_hook
      if @queue.empty?
        @logger.info("Execute empty queue hook.") if @logger
        @hook.exec(:empty_queue, self)
      end
      add_tasks_from_generator
      if @queue.finished?
        @logger.info("Execute finish hook.") if @logger
        @hook.exec(:finish, self)
      end
    end
    private :exec_hook

    def exit
      if @finalization_task
        @message.send_finalization(@finalization_task)
        wait_time = WAIT_TIME_NODE_FINALIZE
      else
        @message.send_exit
        wait_time = WAIT_TIME_NODE_EXIT
      end
      until @message.node_not_exist?
        sleep(wait_time)
        check_connection(true)
      end
      @logger.info("History of tasks") { "\n" + @queue.all_logs } if @logger
      Kernel.exit
    end

    def set_signal_trap
      Signal.trap(:TERM) do
        self.exit
      end
    end

    def set_file_transfer(directory, opts = {})
      user = opts[:user] || @transfer_setting[:user] || ENV['USER']
      host = opts[:host] || @transfer_setting[:host] || 'localhost'
      @ts[:transfer] = DRbQS::Transfer.new(user, host, directory)
      @logger.info("File transfer") { @ts[:transfer].information } if @logger
    end

    def check_message
      while mes = @message.get_message
        case mes
        when :exit_server
          self.exit
        when :request_status
          @message.send_status(@queue.calculating)
        end
      end
    end
    private :check_message

    def task_generator_init
      @task_generator.each { |tgen| tgen.init }
    end
    private :task_generator_init

    def wait
      task_generator_init
      loop do
        check_message
        check_connection
        count_results = @queue.get_result
        exec_hook
        @logger.debug("Calculating tasks: #{@queue.calculating_task_number}") if @logger
        if count_results <= 1
          sleep(WAIT_TIME_NEW_RESULT)
        end
      end
    end

    def test_exec(opts = {})
      task_generator_init
      dummy_client = DRbQS::Client.new(nil, :log_file => $stdout, :log_level => opts[:log_level])
      dummy_task_client = DRbQS::TaskClient.new(nil, @ts[:queue], nil)
      if @ts[:transfer]
        dummy_client.instance_variable_set(:@transfer, DRbQS::TransferTest.new(@ts[:transfer].directory))
      end
      num = 0
      loop do
        exec_hook
        if ary = dummy_task_client.get_task
          task_id, marshal_obj, method_sym, args = ary
          result = dummy_client.instance_eval { execute_task(marshal_obj, method_sym, args) }
          @queue.instance_eval do
            exec_task_hook(task_id, result)
          end
        end
        num += 1
        if opts[:limit] && num >= opts[:limit]
          break
        end
      end
      if @finalization_task
        args = @finalization_task.drb_args(nil)[1..-1]
        dummy_client.instance_eval { execute_task(*args) }
      end
    end

    def test_task_generator(opts = {})
      task_generator_init
      @task_generator.each_with_index do |t, i|
        puts "Test task generator [#{i}]"
        set_num, task_num = t.debug_all_tasks(opts)
        puts "Create: task sets #{set_num}, all tasks #{task_num}"
      end
    end
  end
end
