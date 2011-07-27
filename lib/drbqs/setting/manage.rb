module DRbQS
  class Setting
    class Manage < DRbQS::Setting::Base
      include DRbQS::Command::Argument

      def initialize
        super(:all_keys_defined => true) do
          set_argument_condition(:>, 0)
        end
      end

      def check_all_arguments
        case @mode
        when 'initialize'
          check_argument_size(@argv, :>=, 0, :<=, 1)
        when 'process'
          check_argument_size(@argv, :>=, 0, :<=, 1)
          if @argv[0] && !['clear', 'list'].include?(@argv[0])
            raise DRbQS::Setting::InvalidArgument, "Invalid command 'process #{@argv[0]}'"
          end
        when 'status', 'history'
          check_argument_size(@argv, :==, 1)
        when 'signal'
          case @argv[1]
          when 'server-exit'
            check_argument_size(@argv, :==, 2)
          when 'node-exit-after-task', 'node-wake', 'node-sleep'
            check_argument_size(@argv, :==, 3)
          else
            raise DRbQS::Setting::InvalidArgument, "Invalid signal type '#{@argv[1]}'"
          end
        when 'send'
          check_argument_size(@argv, :==, 3)
          case @argv[0]
          when 'string'
            unless @argv[2]
              raise DRbQS::Setting::InvalidArgument, "String data is not set"
            end
          when 'file'
            unless File.exist?(@argv[2])
              raise DRbQS::Setting::InvalidArgument, "File '#{@argv[2]}' does not exist"
            end
          else
            raise DRbQS::Setting::InvalidArgument, "Invalid option '#{argv[2]}' for 'send'"
          end
        else
          raise DRbQS::Setting::InvalidArgument, "Invalid command '#{@mode}'"
        end
      end
      private :check_all_arguments

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        ary = get_argument
        @mode = ary[0].to_s
        @argv = ary[1..-1]
        check_all_arguments
      end

      def command_initialize
        @manage.set_home_directory(@argv[0])
        @manage.create_config
      end
      private :command_initialize

      def command_process(io)
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
        node_id = @argv[2].to_i
        @manage.__send__(method_name, node_id)
        exit_normally
      end
      private :signal_to_node

      def command_signal
        @manage.set_uri(@argv[0])
        case @argv[1]
        when 'server-exit'
          @manage.send_exit_signal
        when 'node-exit-after-task'
          signal_to_node(:send_node_exit_after_task)
        when 'node-wake'
          signal_to_node(:send_node_wake)
        when 'node-sleep'
          signal_to_node(:send_node_sleep)
        end
      end
      private :command_signal

      def command_send
        @manage.set_uri(@argv[1])
        case @argv[0]
        when 'string'
          data = @argv[2]
        when 'file'
          data = File.read(@argv[2])
        end
        @manage.send_data(data)
      end
      private :command_send

      def exec(io = nil)
        @manage = DRbQS::Manage.new
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
        end
      end
    end
  end
end
