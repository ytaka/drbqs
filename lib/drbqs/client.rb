require 'drbqs/connection'
require 'drbqs/task_client'

module DRbQS

  class Client
    def initialize(access_uri, opts = {})
      @access_uri = access_uri
      @logger = Logger.new(opts[:log_file] || 'drbqs_client.log')
      @logger.level = opts[:log_level] || Logger::ERROR
      @connection = nil
      @task_client = nil
    end

    def execute_task(marshal_obj, method_sym, args)
      obj = Marshal.load(marshal_obj)
      obj.__send__(method_sym, *args)
    end
    private :execute_task

    def connect
      obj = DRbObject.new_with_uri(@access_uri)
      @connection = ConnectionClient.new(obj[:message], @logger)
      node_id = @connection.get_id
      @task_client = TaskClient.new(node_id, obj[:queue], obj[:result], @logger)
      if ary = @connection.get_initialization
        execute_task(*ary)
      end
    end

    def calculate
      cn = Thread.new do
        loop do
          @task_client.add_new_task
          @connection.respond_alive_signal
          @task_client.send_result
          sleep(1)
        end
      end
      exec = Thread.new do
        loop do
          marshal_obj, method_sym, args = @task_client.get
          @task_client.transmit(execute_task(marshal_obj, method_sym, args))
        end
      end
      exec.join
      cn.join
    end
  end

end
