module DRbQS
  class NodeHistory
    def initialize
      @data = {}
    end

    def add(id, id_str)
      @data[id] = [id_str, Time.now]
    end

    def disconnect(id)
      if @data[id]
        @data[id] << Time.now
      end
    end

    def each(&block)
      @data.each(&block)
    end
  end

  class NodeList
    attr_reader :history

    def initialize
      @id = 0
      @list = {}
      @check = []
      @history = NodeHistory.new
    end

    def get_new_id(id_str)
      @id += 1
      @list[@id] = id_str
      @history.add(@id, id_str)
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
        @history.disconnect(id)
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

end
