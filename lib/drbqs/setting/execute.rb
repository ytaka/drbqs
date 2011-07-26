require 'drbqs/execute/process_define'

module DRbQS
  class Setting
    class Execute < DRbQS::Setting::Base
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
      end

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        @port = get_first(:port) do |val|
          val.to_i
        end
        if get(:no_server)
          @server = nil
        else
          @server = get_first(:server) do |val|
            val.intern
          end
        end
        if get(:no_node)
          @node = nil
        else
          @node = get_first(:node) do |val|
            val.split(',').map do |s|
              s.intern
            end
          end
        end
        @definiiton = get_argument[0]
      end

      def exec(io = nil)
        process_def = DRbQS::ProcessDefinition.new
        process_def.load(@definition)
      end
    end
  end
end
