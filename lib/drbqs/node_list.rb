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

end
