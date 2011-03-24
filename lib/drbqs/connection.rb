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
        @message.write([:connect, @id_string])
        @id_number = @message.take([@id_string, Fixnum])[1]
        @logger.info("Get node id: #{@id_number}") if @logger
      end
      @id_number
    end

    def get_initialization
      begin
        ary = @message.read([:initialize, nil, Symbol, nil], 0)
        ary[1..-1]
      rescue Rinda::RequestExpiredError
        nil
      end
    end

    def respond_signal
      begin
        node_id, sym = @message.take([@id_number, Symbol], 0)
        case sym
        when :alive_p
          @message.write([:alive, @id_number])
          @logger.info("Send alive signal of node id #{@id_number}") if @logger
        when :exit
          @logger.info("Get exit signal") if @logger
          return :exit
        end
      rescue Rinda::RequestExpiredError
      end
    end
  end
end
