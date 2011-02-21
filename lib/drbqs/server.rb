require 'drbqs/message'
require 'drbqs/queue'

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

  ROOT_DEFAULT_PORT = 13500

  class Server
    attr_reader :queue

    def initialize(opts = {})
      @port = opts[:port] || ROOT_DEFAULT_PORT
      @acl = opts[:acl]
      @ts = {
        :message => Rinda::TupleSpace.new,
        :queue => Rinda::TupleSpace.new,
        :result => Rinda::TupleSpace.new
      }
      @logger = Logger.new(opts[:log_file] || 'drbqs_server.log')
      @logger.level = opts[:log_level] || Logger::ERROR
      @message = MessageServer.new(@ts[:message], @logger)
      @queue= QueueServer.new(@ts[:queue], @ts[:result], @logger)
      @check_alive = CheckAlive.new(opts[:check_alive])
      @empty_queue_hook = nil
    end

    def start
      DRb.install_acl(@acl) if @acl
      uri = "druby://:#{@port}"
      DRb.start_service(uri, @ts)
      @logger.info("Start DRb service") { uri } if @logger
    end

    def check_connection(force = nil)
      if force || @check_alive.significant_interval?
        @logger.info("Check connection") if @logger
        @message.check_connection
        @check_alive.set_checking
      end
    end
    private :check_connection

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

    def exit
      @message.send_exit
      until @message.node_not_exist?
        sleep(WAIT_NODE_EXIT)
        check_connection(true)
      end
      Kernel.exit
    end

    def wait
      loop do
        @message.get_message
        check_connection
        @queue.get_result
        exec_hook
        sleep(1)
      end
    end
  end
end
