require 'drbqs/node_list'

module DRbQS
  class MessageServer
    def initialize(message, logger = nil)
      @message = message
      @node_list = NodeList.new
      @logger = logger
    end

    def get_message
      begin
        mes = @message.take([:server, Symbol, nil], 0)
        manage_message(*mes[1..2])
      rescue Rinda::RequestExpiredError
        nil
      end
    end

    def manage_message(mes, arg)
      @logger.info("Get message") { [mes, arg] } if @logger
      case mes
      when :connect
        a = [arg, @node_list.get_new_id(arg)]
        @logger.info("New node") { a } if @logger
        @message.write(a)
      when :alive
        @node_list.set_alive(arg)
      when :exit_server
        @logger.info("Get exit message from #{arg.to_s}") if @logger
      when :request_status
        @logger.info("Get status request from #{arg.to_s}") if @logger
      else
        @logger.error("Invalid message from #{arg.to_s}") if @logger
        return nil
      end
      return mes
    end
    private :manage_message

    def check_connection
      deleted = @node_list.delete_not_alive
      @logger.info("IDs of deleted nodes") { deleted } if deleted.size > 0 && @logger
      @node_list.each do |id, str|
        @message.write([id, :alive_p])
      end
      @node_list.set_check_connection
      deleted
    end

    def send_exit
      @node_list.each do |node_id, id_str|
        @message.write([node_id, :exit])
      end
    end

    def time_to_string(t)
      t.strftime("%Y-%m-%d %H:%M:%S")
    end
    private :time_to_string

    def send_status(calculating_task_id)
      s = ''
      @node_list.history.each do |node_id, hist|
        s << sprintf("%4d %s\t", node_id, hist[0])
        if hist.size == 3
          s << "disconnected: (#{time_to_string(hist[1])} - #{time_to_string(hist[1])})\n"
        else
          task_ids = calculating_task_id[node_id]
          s << "task: #{task_ids.map { |num| num.to_s }.join(', ')} (#{time_to_string(hist[1])})\n"
        end
      end
      begin
        @message.take([:status, nil], 0)
      rescue Rinda::RequestExpiredError
      end
      @message.write([:status, s])
    end

    def node_not_exist?
      @node_list.empty?
    end

    # If the task has already set,
    # the method overwrite old task of initialization by new task.
    def set_initialization(task)
      begin
        @message.take([:initialize, nil, Symbol, nil], 0)
      rescue Rinda::RequestExpiredError
      end
      @message.write(task.drb_args(:initialize))
    end

  end

end
