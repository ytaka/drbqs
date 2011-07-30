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

      # Returned values:
      # [:exit_server, nil]
      # [:request_status, nil]
      # [:request_history, nil]
      # [:exit_after_task, node_id]
      # [:wake_node, node_id]
      # [:sleep_node, node_id]
      # [:node_error, [node_id, error_message]]
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
        when :request_history
          @logger.info("Get history request from #{arg.to_s}")
        when :sleep_node
          @logger.info("Get sleep node message for node #{arg.to_s}")
          return [mes, arg]
        when :wake_node
          @logger.info("Get wake node message for node #{arg.to_s}")
          return [mes, arg]
        when :node_error
          @node_list.delete(arg[0], :error)
          @logger.info("Node Error (#{arg[0]})") { arg[1] }
          return [mes, arg[0]]
        when :new_data
          return [mes, arg]
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
        if node_exist?(node_id)
          @message.write([node_id, signal])
        end
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

      def send_sleep(node_id)
        send_signal(node_id, :sleep)
      end

      def send_wake(node_id)
        send_signal(node_id, :wake)
      end

      # Send all nodes a message to finalize and exit.
      def send_finalization
        send_signal_to_all_nodes(:finalize)
      end

      def send_exit_after_task(node_id)
        @node_list.add_to_preparation_to_exit(node_id)
        send_signal(node_id, :exit_after_task)
      end

      def each_node_history(&block)
        @node_list.history.each(&block)
      end

      def send_status(server_status_string)
        begin
          @message.take([:status, nil], 0)
        rescue Rinda::RequestExpiredError
        end
        @message.write([:status, server_status_string])
      end

      def send_history(history_string)
        begin
          @message.take([:history, nil], 0)
        rescue Rinda::RequestExpiredError
        end
        @message.write([:history, history_string])
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

      def shutdown_unused_nodes(calculating_nodes)
        shutdown_nodes = []
        @node_list.each do |node_id, id_str|
          if !@node_list.prepare_to_exit?(node_id) && !calculating_nodes.include?(node_id)
            send_exit_after_task(node_id)
            shutdown_nodes << node_id
          end
        end
        shutdown_nodes
      end
    end

  end
end
