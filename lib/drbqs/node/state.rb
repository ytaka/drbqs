module DRbQS
  class Node
    # Value of state is :sleep, :wait, or :calculate.
    class State
      attr_reader :state

      ALL_STATES = [:sleep, :wait, :calculate]
      DEFAULT_SLEEP_TIME = 300
      LOADAVG_PATH = '/proc/loadavg'

      def initialize(state, opts = {})
        @state = state
        @sleep_at_calculated = nil
        @load_average_threshold = opts[:max_loadavg]
        @sleep_time = opts[:sleep_time] || DEFAULT_SLEEP_TIME
        @auto_wakeup = nil
      end

      def change(state)
        unless ALL_STATES.include?(state)
          raise ArgumentError, "Invalid state of node '#{state}'."
        end
        @state = state
      end

      def calculate?
        @state == :calculate
      end

      def rest?
        !calculate?
      end

      def stop?
        @state == :sleep
      end

      def request?
        @state == :wait
      end

      def change_to_wait
        unless calculate?
          change(:wait)
        end
      end

      def change_to_sleep
        if calculate?
          @sleep_at_calculated = true
        else
          change(:sleep)
        end
      end

      def change_to_calculate
        change(:calculate)
      end

      def change_to_finish_calculating
        if @sleep_at_calculated
          change(:sleep)
        else
          change(:wait)
        end
        @sleep_at_calculated = nil
      end

      def sleep_with_auto_wakeup
        change(:sleep)
        @auto_wakeup = Time.now + @sleep_time
      end

      def check_auto_wakeup
        if @auto_wakeup && Time.now > @auto_wakeup
          change(:wait)
          @auto_wakeup = nil
          return true
        end
        nil
      end

      def get_load_average
        File.read(LOADAVG_PATH).split[0..2].map do |s|
          s.to_f
        end
      end
      private :get_load_average

      def system_busy?
        if @load_average_threshold && File.exist?(LOADAVG_PATH)
          avg = get_load_average
          if (avg[0] + avg[1]) / 2 >= @load_average_threshold
            return true
          end
        end
        nil
      end

      def change_to_sleep_for_busy_system
        if system_busy?
          sleep_with_auto_wakeup
          return true
        end
        nil
      end
    end
  end
end
