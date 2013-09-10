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

      def send_node_wake(node_id)
        send_signal_to_server(:wake_node, node_id)
      end

      def send_node_sleep(node_id)
        send_signal_to_server(:sleep_node, node_id)
      end

      def send_data(data)
        send_signal_to_server(:new_data, data)
      end

      def wait_response(message_cond)
        i = 0
        loop do
          begin
            return @message.take(message_cond, 0)
          rescue Rinda::RequestExpiredError
            i += 1
            if i > MAX_WAIT_TIME
              return nil
            end
            sleep(1)
          end
        end
      end
      private :wait_response

      def get_status
        send_signal_to_server(:request_status, sender_id)
        if mes = wait_response([:status, String])
          return mes[1]
        end
        nil
      end

      def get_history
        send_signal_to_server(:request_history, sender_id)
        if mes = wait_response([:history, String])
          return mes[1]
        end
        nil
      end

      def get_response
        send_signal_to_server(:request_response, [sender_id, Time.now])
        if mes = wait_response([:response, sender_id, nil])
          return true
        end
        nil
      end
    end
  end
end
