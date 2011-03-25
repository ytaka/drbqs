module DRbQS
  module Utils
    def create_logger(log_file, log_level)
      if log_file
        if IO === log_file
          log_output = log_file
        else
          log_output = FileName.create(log_file, :position => :middle, :directory => true, :type => :number)
        end
        logger = Logger.new(log_output)
        logger.level = log_level || Logger::ERROR
        return logger
      end
      return nil
    end
    module_function :create_logger
  end

end
