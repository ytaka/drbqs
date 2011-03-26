require 'drbqs/node_list'

module DRbQS
  class MessageServer
    include HistoryUtils

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

    def send_signal_to_all_nodes(signal)
      @node_list.each do |node_id, id_str|
        @message.write([node_id, signal])
      end
    end
    private :send_signal_to_all_nodes

    def send_exit
      send_signal_to_all_nodes(:exit)
    end

    def send_finalization(task)
      set_finalization(task)
      send_signal_to_all_nodes(:finalize)
    end

    def send_status(calculating_task_id)
      s = ''
      @node_list.history.each do |node_id, events|
        if events.size == 0 || events.size > 2
          raise "Invalid history of nodes: #{events.inspect}"
        end
        connect = events[0]
        s << sprintf("%4d %s\t", node_id, connect[2])
        if disconnect = events[1]
          s << "disconnected: (#{time_to_string(connect[0])} - #{time_to_string(disconnect[0])})\n"
        else
          task_ids = calculating_task_id[node_id]
          s << "task: #{task_ids.map { |num| num.to_s }.join(', ')} (#{time_to_string(connect[0])})\n"
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

    def set_special_task(label, task)
      begin
        @message.take([label, nil, Symbol, nil], 0)
      rescue Rinda::RequestExpiredError
      end
      @message.write(task.drb_args(label))
    end
    private :set_special_task

    # If the task has already set,
    # the method overwrite old task of initialization by new task.
    def set_initialization(task)
      set_special_task(:initialize, task)
    end

    def set_finalization(task)
      set_special_task(:finalization, task)
    end
  end

end
