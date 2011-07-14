module DRbQS
  class Server
    class CheckAlive
      DEFAULT_INTERVAL_TIME = 300

      def initialize(interval)
        @interval = interval || DEFAULT_INTERVAL_TIME
        if !(Numeric === @interval) || @interval < 0
          raise ArgumentError, "Invalid interval time."
        end
        @last = Time.now
      end

      def significant_interval?
        (Time.now - @last) >= @interval
      end

      def set_checking
        @last = Time.now
      end
    end
  end
end
