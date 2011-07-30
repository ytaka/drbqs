module DRbQS
  class Server

    # This class is used in DRbQS::Server::NodeList and DRbQS::Server::Queue to save some histories.
    class History
      include DRbQS::Misc

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
    end

    class TaskHistory < DRbQS::Server::History
      attr_reader :finished_task_number

      def initialize
        super
        @finished_task_number = 0
      end

      def set(id, *args)
        if args[0] == :result
          @finished_task_number += 1
        end
        super(id, *args)
      end

      def log_strings
        s = ''
        each do |task_id, events|
          s << "Task #{task_id}\n"
          events.each do |ev|
            case ev[1]
            when :add
              s << "  #{time_to_history_string(ev[0])}\t#{ev[1]}"
              s << "\t" << ev[2].to_s if ev[2]
              s << "\n"
            when :requeue, :hook
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
end
