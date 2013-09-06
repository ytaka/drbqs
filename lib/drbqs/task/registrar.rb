module DRbQS
  class Task
    # The object of this class is mainly used in DRbQS::Task::Generator#set
    # and calls Fiber.yield.
    class Registrar
      # @param [Hash] data Set instance variables from the hash.
      def initialize(data)
        data.each do |key, val|
          instance_variable_set("@#{key.to_s}", val)
        end
      end

      # Add tasks to server.
      # @param [DRbQS::Task,Array] arg DRbQS::Task object or array of DRbQS::Task objects, which is added to pool of tasks
      def add(arg)
        case arg
        when DRbQS::Task
          Fiber.yield(arg)
        when Array
          arg.each { |t| Fiber.yield(t) }
        else
          raise ArgumentError, "An argument must be DRbQS::Task or an array of DRbQS::Task."
        end
      end

      # Create an object of DRbQS::Task and add it.
      # The arguments are same as {DRbQS::Task}.
      def create_add(*args, &block)
        add(DRbQS::Task.new(*args, &block))
      end

      # Wait finishes of all tasks in queue of a server.
      def wait
        Fiber.yield(:wait)
      end
    end
  end
end
