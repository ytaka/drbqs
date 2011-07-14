module DRbQS
  class History
    include DRbQS::Utils

    def initialize
      @data = Hash.new { |h, k| h[k] = Array.new }
    end

    def set(id, *args)
      @data[id] << args.unshift(Time.now)
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

    def log_strings
      s = ''
      each do |task_id, events|
        s << "Task #{task_id}\n"
        events.each do |ev|
          case ev[1]
          when :add, :requeue, :hook
            s << "  #{time_to_history_string(ev[0])}\t#{ev[1]}\n"
          when :calculate, :result
            s << "  #{time_to_history_string(ev[0])}\t#{ev[1]} (node #{ev[2]})\n"
          end
        end
      end
      s
    end
  end
end
