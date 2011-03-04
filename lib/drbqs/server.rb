require 'drbqs/message'
require 'drbqs/queue'
require 'drbqs/acl_file'

module DRbQS
  class CheckAlive
    def initialize(interval)
      @interval = interval || 300
      @last = Time.now
    end

    def significant_interval?
      (Time.now - @last) >= @interval
    end

    def set_checking
      @last = Time.now
    end
  end

  class Server
    attr_reader :queue

    # :port
    # :acl
    # :log_file
    # :log_level
    # :check_alive
    def initialize(opts = {})
      @port = opts[:port] || ROOT_DEFAULT_PORT
      @acl = acl_init(opts[:acl])
      @ts = {
        :message => Rinda::TupleSpace.new,
        :queue => Rinda::TupleSpace.new,
        :result => Rinda::TupleSpace.new
      }
      if opts[:log_file]
        @logger = Logger.new(opts[:log_file])
        @logger.level = opts[:log_level] || Logger::ERROR
      else
        @logger = nil
      end
      @message = MessageServer.new(@ts[:message], @logger)
      @queue= QueueServer.new(@ts[:queue], @ts[:result], @logger)
      @check_alive = CheckAlive.new(opts[:check_alive])
      @empty_queue_hook = nil
    end

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

    def start
      DRb.install_acl(@acl) if @acl
      uri = "druby://:#{@port}"
      DRb.start_service(uri, @ts)
      @logger.info("Start DRb service") { uri } if @logger
    end

    def check_connection(force = nil)
      if force || @check_alive.significant_interval?
        @logger.debug("Check connection") if @logger
        @message.check_connection
        @check_alive.set_checking
      end
    end
    private :check_connection

    def set_initialization_task(task)
      @message.set_initialization(task)
    end

    def set_empty_queue_hook(&block)
      if block_given?
        @empty_queue_hook = block
      else
        @empty_queue_hook = nil
      end
    end

    def set_finish_hook(&block)
      if block_given?
        @finish_hook = block
      else
        @finish_hook = nil
      end
    end

    def exec_hook
      if @empty_queue_hook && @queue.empty?
        @logger.info("Execute empty queue hook.") if @logger
        @empty_queue_hook.call(self)
      end
      if @finish_hook && @queue.finished?
        @logger.info("Execute finish hook.") if @logger
        @finish_hook.call(self)
      end
    end
    private :exec_hook

    WAIT_NODE_EXIT = 3
    WAIT_NEW_RESULT = 1

    def exit
      @message.send_exit
      until @message.node_not_exist?
        sleep(WAIT_NODE_EXIT)
        check_connection(true)
      end
      Kernel.exit
    end

    def set_signal_trap
      Signal.trap(:TERM) do
        self.exit
      end
    end

    def check_message
      if @message.get_message == :exit_server
        self.exit
      end
    end
    private :check_message

    def wait
      loop do
        check_message
        check_connection
        count_results = @queue.get_result
        exec_hook
        @logger.debug("Calculating tasks: #{@queue.calculating_task_number}") if @logger
        if count_results <= 1
          sleep(WAIT_NEW_RESULT)
        end
      end
    end
  end
end
