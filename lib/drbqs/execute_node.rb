module DRbQS

  class ExecuteNode
    NODE_INTERVAL_TIME = 1

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
        client = DRbQS::Client.new(@uri, :log_level => @log_level, :log_file => get_log_file)
        client.connect
        client.calculate
      end
    end
    private :create_process

    def execute(process_num)
      process_num.times do |i|
        create_process
        sleep(NODE_INTERVAL_TIME)
      end
    end

    def wait
      Process.waitall 
    end
  end

end
