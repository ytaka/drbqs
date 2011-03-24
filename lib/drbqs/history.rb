module DRbQS
  class History
    def initialize
      @data = Hash.new { |h, k| h[k] = Array.new }
    end

    def set(id, *args)
      @data[id] << [Time.now] + args
    end

    def size
      @data.size
    end

    def events(id)
      @data[id]
    end

    def number_of_events(id)
      @data[id].size
    end

    def each(&block)
      @data.each(&block)
    end
  end
end
