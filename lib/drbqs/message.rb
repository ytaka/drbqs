module DRbQS
  class NodeList
    def initialize
      @id = 0
      @list = {}
      @check = []
    end

    def get_new_id(id_str)
      @id += 1
      @list[@id] = id_str
      @id
    end

    def each(&block)
      @list.each(&block)
    end

    def set_check_connection
      @check = @list.keys
    end

    def delete_not_alive
      @check.each do |id|
        @list.delete(id)
      end
      deleted = @check
      @check = []
      deleted
    end

    def set_alive(id)
      @check.delete(id)
    end

    def empty?
      @list.size == 0
    end
  end

  class MessageServer
    def initialize(message, logger = nil)
      @message = message
      @node_list = NodeList.new
      @logger = logger
    end

    def get_message
      begin
        mes = @message.take([Symbol, nil], 0)
        manage_message(*mes)
      rescue Rinda::RequestExpiredError
      end
    end

    def manage_message(mes, arg)
      @logger.debug("Get message") { [mes, arg] } if @logger
      case mes
      when :connect
        a = [arg, @node_list.get_new_id(arg)]
        @logger.debug("New node") { a } if @logger
        @message.write(a)
      when :alive
        @node_list.set_alive(arg)
      else
        puts "Invalid message from #{arg.to_s}"
      end
    end
    private :manage_message

    def check_connection
      deleted = @node_list.delete_not_alive
      @logger.info("IDs of deleted nodes") { deleted } if @logger
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

    def node_not_exist?
      @node_list.empty?
    end

    # If the task has already set,
    # the method overwrite old task of initialization by new task.
    def set_initialization(task)
      begin
        @message.take([:initialize, nil, Symbol, nil], 0)
      rescue
      end
      @message.write(task.drb_args(:initialize))
    end

  end

end
