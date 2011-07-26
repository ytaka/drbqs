module DRbQS
  class Setting
    class Manage < DRbQS::Setting::Base
      include DRbQS::Command::Argument

      def initialize
        super(:all_keys_defined => true) do
          set_argument_condition(:>, 0)
        end
      end

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        @argv = get_argument
        @mode = @argv.shift
        @manage = DRbQS::Manage.new
      end

      def command_initialize
        check_argument_size(@argv, :>=, 0, :<=, 1)
        @manage.set_home_directory(@argv[0])
        @manage.create_config
      end
      private :command_initialize

      def command_process(io)
        check_argument_size(@argv, :>=, 0, :<=, 1)
        if @argv[0] == 'clear'
          @manage.clear_process
          return true
        end
        result = ''
        list = @manage.list_process
        result << "Server\n"
        list[:server].each do |uri, data|
          result << "#{uri}\n"
          data.each do |k, v|
            result << sprintf("  %-10s  %s\n", k, v)
          end
        end
        result << "\nNode\n"
        list[:node].each do |pid, data|
          result << "#{pid}\n"
          data.each do |k, v|
            result << sprintf("  %-10s  %s\n", k, v)
          end
        end
        io.print result if io
      end
      private :command_process

      def request_to_server(io, method_name)
        check_argument_size(@argv, :==, 1)
        @manage.set_uri(@argv[0])
        if status = @manage.__send__(method_name)
          io.puts status if io
        end
      end
      private :request_to_server

      def command_status(io)
        request_to_server(io, :get_status)
      end
      private :command_status

      def command_history
        request_to_server(io, :get_history)
      end
      private :command_history

      def signal_to_node(method_name)
        check_argument_size(@argv, :==, 3)
        node_id = @argv[2].to_i
        @manage.__send__(method_name, node_id)
        exit_normally
      end
      private :signal_to_node

      def command_signal
        @manage.set_uri(@argv[0])
        signal = @argv[1]
        case signal
        when 'server-exit'
          check_argument_size(@argv, :==, 2)
          @manage.send_exit_signal
        when 'node-exit-after-task'
          signal_to_node(:send_node_exit_after_task)
        when 'node-wake'
          signal_to_node(:send_node_wake)
        when 'node-sleep'
          signal_to_node(:send_node_sleep)
        else
          raise ArgumentError, "Invalid signal '#{signal}'"
        end
      end
      private :command_signal

      def command_send
        type = @argv.shift
        @manage.set_uri(@argv.shift)
        case type
        when 'string'
          unless data = @argv[0]
            raise ArgumentError, "String data is not set"
          end
        when 'file'
          if File.exist?(@argv[0])
            data = File.read(@argv[0])
          else
            raise ArgumentError, "File '#{@argv[0]}' does not exist"
          end
        else
          raise ArgumentError, "Invalid option '#{type}' for 'send'"
        end
        @manage.send_data(data)
      end
      private :command_send

      def exec(io = nil)
        case @mode
        when 'initialize'
          command_initialize
        when 'process'
          command_process(io)
        when 'status'
          command_status(io)
        when 'history'
          command_history(io)
        when 'signal'
          command_signal
        when 'send'
          command_send
        else
          raise ArgumentError, "Invalid command '#{@mode}'"
        end
      end
    end
  end
end
