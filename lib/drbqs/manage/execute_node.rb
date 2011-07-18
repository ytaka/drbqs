module DRbQS

  class ExecuteNode
    attr_reader :pid

    def initialize(uri, log_prefix, log_level)
      @uri = uri
      @log_level = log_level
      if log_prefix
        @fname = FileName.new(log_prefix, :position => :suffix, :type => :time,
                              :add => :always, :directory => :parent,
                              :format => lambda { |t| t.strftime("%Y%m%d_%H%M_#{Process.pid}.log") })
      else
        @fname = nil
      end
      @pid = []
    end

    def get_log_file
      if @fname
        return @fname.create
      end
      return STDOUT
    end
    private :get_log_file

    def create_process
      @pid << fork do
        node = DRbQS::Node.new(@uri, :log_level => @log_level, :log_file => get_log_file)
        node.connect
        node.calculate
      end
    end
    private :create_process

    def execute(process_num, interval = 0)
      process_num.times do |i|
        create_process
        sleep(interval) if interval > 0
      end
    end

    def wait
      Process.waitall
    end
  end

end
