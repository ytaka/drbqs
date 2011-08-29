module DRbQS
  class Setting
    class Node < DRbQS::Setting::Base
      LOG_PREFIX_DEFAULT = 'drbqs_node'

      def initialize
        super(:all_keys_defined => true, :log_level => true, :daemon => true) do
          register_key(:load, :check => [:>, 0], :add => true)
          register_key(:process, :check => 1, :default => [1])
          register_key(:group, :add => true)
          register_key(:loadavg, :check => 1)
          register_key(:log_prefix, :check => 1, :default => [LOG_PREFIX_DEFAULT])
          register_key(:log_stdout, :bool => true)
          register_key(:connect, :check => 1)
          set_argument_condition(:==, 1)
        end
      end

      def preprocess!
        if connect = get_first(:connect)
          value.argument.unshift(connect)
          clear(:connect)
        end
      end
      private :preprocess!

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        parse_load
        parse_group
        parse_loadavg
        if !get(:log_stdout)
          @options[:log_prefix] = get_first(:log_prefix) do |val|
            str = val.to_s
            str += 'out' if /\/$/ =~ str
            str
          end
        end
        @process_num = get_first(:process)
        @uri = get_argument[0]
      end

      def parse_load
        @options[:load] = []
        get(:load).to_a.each do |path|
          @options[:load] << File.expand_path(path)
        end
      end
      private :parse_load

      def parse_loadavg
        @options[:node_opts] ||= {}
        if args = get(:loadavg)
          max_loadavg, sleep_time = args[0].split(':', -1)
          @options[:node_opts][:max_loadavg] = max_loadavg && max_loadavg.size > 0 ? max_loadavg.to_f : nil
          @options[:node_opts][:sleep_time] = sleep_time && sleep_time.size > 0 ? sleep_time.to_i : nil
        end
      end
      private :parse_loadavg

      def parse_group
        if args = get(:group)
          @options[:node_opts] ||= {}
          @options[:node_opts][:group] = args.map { |a| a.intern }
        end
      end
      private :parse_group

      def exec(io = nil)
        return true if exec_as_daemon

        @options[:load].each do |path|
          io.puts "load #{path}" if io
          unless File.exist?(path)
            raise DRbQS::Setting::InvalidArgument, "#{path} does not exist."
          end
          load path
        end

        if io
          io.puts "Connect to #{@uri}"
          io.puts "Execute #{@process_num} processes"
        end

        exec_node = DRbQS::Execution::ExecuteNode.new(@uri, @options[:log_prefix], @options[:log_level], @options[:node_opts])
        exec_node.execute(@process_num)
        exec_node.wait
        true
      end
    end
  end
end
