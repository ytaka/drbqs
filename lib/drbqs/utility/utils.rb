module DRbQS
  module Utils
    def create_logger(log_file, log_level)
      if log_file
        if IO === log_file
          log_output = log_file
        else
          log_output = FileName.create(log_file, :position => :middle, :directory => :parent, :type => :number)
        end
        logger = Logger.new(log_output)
        logger.level = log_level || Logger::ERROR
        return logger
      end
      return nil
    end
    module_function :create_logger

    STRINGS_FOR_KEY = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a

    def self.random_key(size = 20)
      n = STRINGS_FOR_KEY.size
      Array.new(size) do
        STRINGS_FOR_KEY[rand(n)]
      end.join
    end
  end

end
