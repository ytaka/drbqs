require 'socket'

module DRbQS
  # The class of connection to s.erver.
  class ConnectionClient
    def initialize(message, logger = nil)
      @message = message
      @logger = logger
      @id_number = nil
      @id_string = create_id_string
    end

    def create_id_string
      t = Time.now
      sprintf("#{Socket.gethostname}:%d", Process.pid)
    end
    private :create_id_string

    def get_id
      unless @id_number
        @message.write([:server, :connect, @id_string])
        @id_number = @message.take([@id_string, Fixnum])[1]
        @logger.info("Get node id: #{@id_number}") if @logger
      end
      @id_number
    end

    def get_special_task(label)
      begin
        ary = @message.read([label, nil, Symbol, nil], 0)
        ary[1..-1]
      rescue Rinda::RequestExpiredError
        nil
      end
    end
    private :get_special_task

    def get_initialization
      get_special_task(:initialize)
    end

    def get_finalization
      get_special_task(:finalize)
    end

    def respond_signal
      begin
        node_id, sym = @message.take([@id_number, Symbol], 0)
        @logger.info("Get signal: #{sym.inspect}") if @logger
        case sym
        when :alive_p
          @message.write([:server, :alive, @id_number])
          @logger.info("Send alive signal of node id #{@id_number}") if @logger
        when :exit, :finalize, :exit_after_task
          return sym
        else
          raise "Get invalid signal: #{sym.inspect}"
        end
      rescue Rinda::RequestExpiredError
      end
    end

    def send_node_error(error_message)
      @message.write([:server, :node_error, [@id_number, error_message]])
    end
  end
end
