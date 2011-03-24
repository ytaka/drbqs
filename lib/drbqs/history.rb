module DRbQS
  class History
    def initialize
      @data = {}
    end

    def begin(id, *args)
      @data[id] = args + [Time.now]
    end

    def finish(id)
      if @data[id]
        @data[id] << Time.now
      end
    end

    def each(&block)
      @data.each(&block)
    end
  end
end
