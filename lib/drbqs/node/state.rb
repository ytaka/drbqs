module DRbQS
  class Node
    # Value of state is :sleep, :wait, or :calculate.
    class State
      attr_reader :state

      ALL_STATES = [:sleep, :wait, :calculate]

      def initialize(state)
        @state = state
        @sleep_at_calculated = nil
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

      def change_to_calculated
        if @sleep_at_calculated
          change(:sleep)
        else
          change(:wait)
        end
        @sleep_at_calculated = nil
      end
    end
  end
end
