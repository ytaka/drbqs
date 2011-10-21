module DRbQS
  class Execution
    class ExecuteNode
      def initialize(uri, log_prefix, log_level, node_opts = {})
        @uri = uri
        @log_level = log_level
        if log_prefix
          @fname = FileName.new(log_prefix, :position => :suffix, :type => :time,
                                :add => :always, :directory => :parent,
                                :format => lambda { |t| t.strftime("%Y%m%d_%H%M_#{Process.pid}.log") })
        else
          @fname = nil
        end
        @node_opts = node_opts
      end

      def get_log_file
        if @fname
          return @fname.create
        end
        return STDOUT
      end
      private :get_log_file

      def execute(process_num, interval = 0)
        opts = @node_opts.merge({ :log_level => @log_level, :log_file => get_log_file, :process => process_num })
        node = DRbQS::Node.new(@uri, opts)
        node.connect
        node.calculate
      end
    end
  end
end
