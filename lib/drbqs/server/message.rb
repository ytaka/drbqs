require 'drbqs/server/node_list'

module DRbQS
  class Server
    class Message
      include DRbQS::Misc

      def initialize(message, logger = DRbQS::LoggerDummy.new)
        @message = message
        @node_list = DRbQS::Server::NodeList.new
        @logger = logger
      end

      def get_message
        begin
          mes = @message.take([:server, Symbol, nil], 0)
          manage_message(*mes[1..2])
        rescue Rinda::RequestExpiredError
          nil
        end
      end

      def manage_message(mes, arg)
        @logger.info("Get message") { [mes, arg] }
        case mes
        when :connect
          a = [arg, @node_list.get_new_id(arg)]
          @logger.info("New node") { a }
          @message.write(a)
        when :alive
          @node_list.set_alive(arg)
        when :exit_server
          @logger.info("Get exit message from #{arg.to_s}")
        when :exit_after_task
          @logger.info("Get exit message for node #{arg.to_s} after current task")
          return [mes, arg]
        when :request_status
          @logger.info("Get status request from #{arg.to_s}")
        when :node_error
          @node_list.delete(arg[0])
          @logger.info("Node Error (#{arg[0]})") { arg[1] }
          return [mes, arg[0]]
        else
          @logger.error("Invalid message from #{arg.to_s}")
          return nil
        end
        [mes]
      end
      private :manage_message

      def check_connection
        deleted = @node_list.delete_not_alive
        @logger.info("IDs of deleted nodes") { deleted } if deleted.size > 0 && @logger
        @node_list.each do |id, str|
          @message.write([id, :alive_p])
        end
        @node_list.set_check_connection
        deleted
      end

      def send_signal(node_id, signal)
        @message.write([node_id, signal])
      end
      private :send_signal

      def send_signal_to_all_nodes(signal)
        @node_list.each do |node_id, id_str|
          send_signal(node_id, signal)
        end
      end
      private :send_signal_to_all_nodes

      # Send all nodes a message to exit.
      def send_exit
        send_signal_to_all_nodes(:exit)
      end

      # Send all nodes a message to finalize and exit.
      def send_finalization
        send_signal_to_all_nodes(:finalize)
      end

      def send_exit_after_task(node_id)
        send_signal(node_id, :exit_after_task)
      end

      def send_status(calculating_task_id)
        s = ''
        @node_list.history.each do |node_id, events|
          if events.size == 0 || events.size > 2
            raise "Invalid history of nodes: #{events.inspect}"
          end
          connect = events[0]
          s << sprintf("%4d %s\t", node_id, connect[2])
          if disconnect = events[1]
            s << "disconnected: (#{time_to_history_string(connect[0])} - #{time_to_history_string(disconnect[0])})\n"
          else
            task_ids = calculating_task_id[node_id].to_a
            s << "task: #{task_ids.map { |num| num.to_s }.join(', ')} (#{time_to_history_string(connect[0])})\n"
          end
        end
        begin
          @message.take([:status, nil], 0)
        rescue Rinda::RequestExpiredError
        end
        @message.write([:status, s])
      end

      def get_all_nodes
        @node_list.list.dup
      end

      def node_not_exist?
        @node_list.empty?
      end

      def node_exist?(node_id)
        @node_list.exist?(node_id)
      end

      def set_special_task(label, task)
        begin
          @message.take([label, nil, Symbol, nil], 0)
        rescue Rinda::RequestExpiredError
        end
        @message.write(task.drb_args(label))
      end
      private :set_special_task

      # If the task has already set,
      # the method overwrite old task of initialization by new task.
      def set_initialization(task)
        set_special_task(:initialize, task)
      end

      def set_finalization(task)
        set_special_task(:finalization, task)
      end
    end

  end
end
