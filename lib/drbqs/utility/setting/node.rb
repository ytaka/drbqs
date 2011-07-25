module DRbQS
  class Setting
    class Node < DRbQS::Setting::Base
      LOG_PREFIX_DEFAULT = 'drbqs_node'

      def initialize
        super(:all_keys_defined => true, :log_level => true, :daemon => true) do
          register_key(:load, :check => [:>, 0], :add => true)
          register_key(:loadavg, :check => 1)
          register_key(:log_prefix, :check => 1, :default => [LOG_PREFIX_DEFAULT])
          register_key(:log_stdout, :bool => true)
          set_argument_condition(:<=, 2)
        end
      end

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        parse_load
        parse_loadavg
        if !get(:log_stdout)
          @options[:log_prefix] = get_first(:log_prefix) do |val|
            str = val.to_s
            str += 'out' if /\/$/ =~ str
            str
          end
        end
        parse_argument
      end

      def parse_load
        get(:load).each do |path|
          epath = File.expand_path(v)
          unless File.exist?(epath)
            raise ArgumentError, "#{path} does not exist."
          end
          @options[:load] << epath
        end
      end
      private :parse_load

      def parse_loadavg
        if args = get(:loadavg)
          max_loadavg, sleep_time = args[0].split(':', -1)
          @options[:node_opts][:max_loadavg] = max_loadavg && max_loadavg.size > 0 ? max_loadavg.to_f : nil
          @options[:node_opts][:sleep_time] = sleep_time && sleep_time.size > 0 ? sleep_time.to_i : nil
        end
      end
      private :parse_loadavg

      def parse_argument
        args = get_argument
        @process_num = 1
        @uri = nil
        args.each do |arg|
          if /^\d+$/ =~ arg
            @process_num = arg.to_i
          elsif @uri
            raise ArgumentError, "More than one uris is set."
          else
            @uri = arg
          end
        end
        @uri ||= DRbQS::Misc.create_uri
      end
      private :parse_argument

      def exec(io = nil)
        return true if exec_as_daemon

        @options[:load].each do |v|
          io.puts "load #{v}" if io
          load v
        end

        if io
          io.puts "Connect to #{@uri}"
          io.puts "Execute #{@process_num} processes"
        end

        exec_node = DRbQS::ExecuteNode.new(@uri, @options[:log_prefix], @options[:log_level], @options[:node_opts])
        exec_node.execute(@process_num)
        exec_node.wait
        true
      end
    end
  end
end
