require 'drbqs/server/history'

module DRbQS
  class Server
    class NodeList
      attr_reader :history, :list

      def initialize
        @id = 0
        @list = {}
        @check = []
        @prepare_to_exit = []
        @history = DRbQS::Server::History.new
      end

      def get_new_id(id_str)
        @id += 1
        @list[@id] = id_str
        @history.set(@id, :connect, @list[@id])
        @id
      end

      def each(&block)
        @list.each(&block)
      end

      def set_check_connection
        @check = @list.keys
      end

      def delete(id, history_state)
        @list.delete(id)
        @prepare_to_exit.delete(id)
        @history.set(id, history_state)
      end

      def delete_not_alive
        @check.each do |id|
          delete(id, :disconnect)
        end
        deleted = @check
        @check = []
        deleted
      end

      def set_alive(id)
        @check.delete(id)
      end

      def empty?
        @list.size == 0
      end

      def exist?(id)
        @list.find { |a| a[0] == id }
      end

      def prepare_to_exit?(node_id)
        @history.set(node_id, :set_exitting)
        @prepare_to_exit.include?(node_id)
      end

      def add_to_preparation_to_exit(node_id)
        unless prepare_to_exit?(node_id)
          @prepare_to_exit << node_id
        end
      end
    end

  end
end

