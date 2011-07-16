require 'socket'

module DRbQS
  class Node
    # The class of connection to server.
    class Connection
      attr_reader :id, :node_number

      def initialize(message, logger = DRbQS::LoggerDummy.new)
        @message = message
        @logger = logger
        @node_number = nil
        @id = create_id_string
      end

      def create_id_string
        t = Time.now
        sprintf("#{Socket.gethostname}:%d", Process.pid)
      end
      private :create_id_string

      def node_number
        unless @node_number
          @message.write([:server, :connect, @id])
          @node_number = @message.take([@id, Fixnum])[1]
          @logger.info("Get node id: #{@node_number}")
        end
        @node_number
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
          node_id, sym = @message.take([@node_number, Symbol], 0)
          @logger.info("Get signal: #{sym.inspect}")
          case sym
          when :alive_p
            @message.write([:server, :alive, @node_number])
            @logger.info("Send alive signal of node id #{@node_number}")
          when :exit, :finalize, :exit_after_task
            return sym
          else
            raise "Get invalid signal: #{sym.inspect}"
          end
        rescue Rinda::RequestExpiredError
        end
      end

      def send_node_error(error_message)
        @message.write([:server, :node_error, [@node_number, error_message]])
      end
    end
  end
end
