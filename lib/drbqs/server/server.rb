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
    # :signal_trap
    #   Set trapping signal.
    # :scp_user
    #   Set user of scp.
    # :scp_host
    #   Set host of scp.
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
      hook_init(opts[:finish_exit])
      set_signal_trap if opts[:signal_trap]
      @finalization_task = nil
      @transfer_setting = DRbQS::Server::TransferSetting.new(opts[:scp_host], opts[:scp_user], opts[:file_directory])
      @config = DRbQS::Config.new
    end

    def transfer_directory
      @ts[:transfer] && @ts[:transfer].directory
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

    def hook_init(finish_exit)
      @hook = DRbQS::Server::Hook.new
      @hook.set_finish_exit { self.exit } if finish_exit
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

    def set_initialization_task(task)
      @message.set_initialization(task)
    end

    def set_finalization_task(task)
      @finalization_task = task
      @message.set_finalization(@finalization_task)
    end

    # +key+ is :empty_queue or :finish_exit.
    # &block takes self as an argument.
    def add_hook(key, name = nil, &block)
      @hook.add(key, name, &block)
    end

    def delete_hook(key, name = nil)
      @hook.delete(key, name)
    end

    def exec_finish_hook
      @logger.info("Execute finish hook.")
      @hook.exec(:finish, self)
    end
    private :exec_finish_hook
    
    def exec_hook
      if @queue.empty?
        @logger.info("Execute empty queue hook.")
        @hook.exec(:empty_queue, self)
      end
      if !generator_waiting? || @queue.finished?
        add_tasks_from_generator
      end
      if !generator_waiting? && @queue.finished?
        exec_finish_hook
      end
    end
    private :exec_hook

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
      if transfer = @transfer_setting.create(directory, opts)
        @ts[:transfer] = transfer
        @logger.info("File transfer") { transfer.information }
      end
    end

    def check_message
      while mes_arg = @message.get_message
        mes, arg = mes_arg
        case mes
        when :exit_server
          self.exit
        when :request_status
          @message.send_status(@queue.calculating)
        when :exit_after_task
          node_id = arg
          if @message.node_exist?(node_id)
            @message.send_exit_after_task(node_id)
          end
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

    def start_profile
      require 'ruby-prof'
      RubyProf.start
    end
    private :start_profile

    def finish_profile
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      # printer = RubyProf::GraphPrinter.new(result)
      # printer = RubyProf::CallTreePrinter.new(result)
      printer.print(STDOUT)
    end
    private :finish_profile

    def test_exec(opts = {})
      first_task_generator_init
      dummy_node = DRbQS::Node.new(nil, :log_file => $stdout, :log_level => opts[:log_level])
      dummy_task_client = DRbQS::Node::TaskClient.new(nil, @ts[:queue], nil)
      if @ts[:transfer]
        dummy_node.instance_variable_set(:@transfer, DRbQS::TransferClient::Local.new(@ts[:transfer].directory))
      end
      num = 0
      start_profile if opts[:profile]
      loop do
        exec_hook
        if ary = dummy_task_client.get_task
          task_id, marshal_obj, method_sym, args = ary
          result = dummy_node.instance_eval { execute_task(marshal_obj, method_sym, args) }
          @queue.exec_task_hook(self, task_id, result)
        end
        num += 1
        if opts[:limit] && num >= opts[:limit]
          break
        end
      end
      finish_profile if opts[:profile]
      if @finalization_task
        args = @finalization_task.drb_args(nil)[1..-1]
        dummy_node.instance_eval { execute_task(*args) }
      end
      exec_finish_hook
    end

    def test_task_generator(opts = {})
      @task_generator.each_with_index do |t, i|
        puts "Test task generator [#{i}]"
        t.init
        set_num, task_num = t.debug_all_tasks(opts)
        puts "Create: task sets #{set_num}, all tasks #{task_num}"
      end
    end
  end
end