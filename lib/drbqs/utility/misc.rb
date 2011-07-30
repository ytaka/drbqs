require 'sys/proctable'

module DRbQS
  class LoggerDummy
    def info(*args)
    end

    def warn(*args)
    end

    def error(*args)
    end

    def debug(*args)
    end
  end

  module Misc
    # :port
    # :host
    # :unix
    def create_uri(opts = {})
      if opts[:port] || !opts[:unix]
        port = opts[:port] || ROOT_DEFAULT_PORT
        "druby://#{opts[:host]}:#{port}"
      elsif opts[:host]
        raise ArgumentError, "We can not set hostname to unix domain socket."
      else
        path = File.expand_path(opts[:unix])
        if !File.directory?(File.dirname(path))
          raise ArgumentError, "Directory #{File.dirname(path)} does not exist."
        elsif File.exist?(path)
          raise ArgumentError, "File #{path} already exists."
        end
        "drbunix:#{path}"
      end
    end
    module_function :create_uri

    def create_logger(log_file, log_level)
      if IO === log_file
        log_output = log_file
      elsif log_file
        log_output = FileName.create(log_file, :position => :middle, :directory => :parent, :type => :number)
      else
        log_output = STDOUT
      end
      logger = Logger.new(log_output)
      logger.level = log_level || Logger::ERROR
      logger
    end
    module_function :create_logger

    def time_to_history_string(t)
      t.strftime("%Y-%m-%d %H:%M:%S")
    end
    module_function :time_to_history_string

    def time_to_history_string2(t)
      t.strftime("%m-%d %H:%M:%S")
    end
    module_function :time_to_history_string2

    STRINGS_FOR_KEY = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a

    def random_key(size = 20)
      n = STRINGS_FOR_KEY.size
      Array.new(size) do
        STRINGS_FOR_KEY[rand(n)]
      end.join
    end
    module_function :random_key

    # If process of +pid+ does not exist or its state is zombie then the method return false.
    # If +pid+ is invalid then the method also returns false.
    def process_running_normally?(pid)
      Integer === pid && (ps_table = Sys::ProcTable.ps(pid)) && (ps_table.state != 'Z')
    end
    module_function :process_running_normally?

    def output_error(err, io = $stderr)
      backtrace = err.backtrace
      io.puts "#{backtrace[0]}: #{err.to_s} (#{err.class})"
      if backtrace.size > 1
        io.puts "        from #{backtrace[1..-1].join("\n        from ")}"
      end
    end
    module_function :output_error
  end

end
