module DRbQS
  # The class of connection to s.erver.
  class ConnectionClient
    def initialize(message, logger = nil)
      @message = message
      @logger = logger
      @id = nil
    end

    def create_id_string
      t = Time.now
      sprintf("%d%d%d", t.to_i, t.usec, rand(1000))
    end
    private :create_id_string

    def get_id
      s = create_id_string
      @message.write([:connect, s])
      @id = @message.take([s, Fixnum])[1]
    end

    def get_initialization
      begin
        ary = @message.read([:initialize, nil, Symbol, nil], 0)
        ary[1..-1]
      rescue
        nil
      end
    end

    def respond_alive_signal
      begin
        node_id, sym = @message.take([@id, Symbol], 0)
        case sym
        when :alive_p
          @message.write([:alive, @id])
        when :exit
          Kernel.exit
        end
      rescue
      end
    end
  end
end
