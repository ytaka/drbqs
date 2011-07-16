module DRbQS
  class Manage
    class SendSignal
      MAX_WAIT_TIME = 10

      def initialize(message)
        @message = message
      end

      def sender_id
        "#{Socket.gethostname}/#{Process.pid}"
      end

      def send_signal_to_server(signal, arg)
        @message.write([:server, signal, arg])
      end
      private :send_signal_to_server

      def send_exit_signal
        send_signal_to_server(:exit_server, sender_id)
      end

      def send_node_exit_after_task(node_id)
        send_signal_to_server(:exit_after_task, node_id)
      end

      def get_status
        send_signal_to_server(:request_status, sender_id)
        i = 0
        loop do
          begin
            mes = @message.take([:status, String], 0)
            return mes[1]
          rescue Rinda::RequestExpiredError
            i += 1
            if i > MAX_WAIT_TIME
              return nil
            end
            sleep(1)
          end
        end
      end
    end
  end
end
