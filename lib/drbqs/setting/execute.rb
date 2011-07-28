require 'drbqs/execute/process_define'

module DRbQS
  class Setting
    class Execute < DRbQS::Setting::Base
      attr_accessor :server_argument

      def initialize
        super(:all_keys_defined => true) do
          [:port, :server, :node].each do |key|
            register_key(key, :check => 1)
          end
          [:no_server, :no_node].each do |key|
            register_key(key, :bool => true)
          end
          set_argument_condition(:==, 1)
        end
        @server_argument = []
      end

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        @port = get_first(:port) do |val|
          val.to_i
        end
        @no_server = get_first(:no_server)
        @server = get_first(:server) do |val|
          val.intern
        end
        @no_node = get_first(:no_node)
        @node = get_first(:node) do |val|
          val.split(',').map do |s|
            s.intern
          end
        end
        @definition = get_argument[0]
      end

      def exec(io = nil)
        process_def = DRbQS::ProcessDefinition.new(@server, @node, @port, io)
        process_def.load(@definition)
        unless @no_server
          process_def.execute_server(@server_argument)
        end
        unless @no_node
          process_def.execute_node
        end
        true
      end
    end
  end
end
