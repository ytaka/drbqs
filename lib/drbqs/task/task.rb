require 'drbqs/utility/transfer/transfer_file_list'
require 'drbqs/utility/transfer/transfer'
require 'drbqs/task/registrar'
require 'drbqs/task/task_generator'

module DRbQS

  # The tasks defined by this class are sent to nodes and
  # calculated by the nodes.
  class Task
    attr_reader :hook
    attr_accessor :message

    # Nodes calculate by obj.method_sym(*args) and send the result to their server.
    # Then the server executes &hook with a server instance and an object of result.
    # For the communication of a server and nodes we must convert obj to a string
    # by Marshal.dump.
    # @param [Object] obj An object that has a method "method_sym"
    # @param [Symbol] method_sym Method name of calculation
    # @param [String] message Message for a task
    # @param [Proc] hook A server execute hook as a callback when the server receive the result
    def initialize(obj, method_sym, args = [], message = nil, &hook)
      begin
        @marshal_obj = Marshal.dump(obj)
      rescue
        raise "Can not dump an instance of #{obj.class}."
      end
      @method_sym = method_sym.intern
      @args = args || []
      unless Array === @args
        raise "Arguments of task must be an array."
      end
      @message = message
      @hook = hook
    end

    def drb_args(task_id)
      [task_id, @marshal_obj, @method_sym, @args]
    end

    def same_target?(other)
      @marshal_obj == other.instance_variable_get(:@marshal_obj) &&
        @method_sym == other.instance_variable_get(:@method_sym) &&
        @args == other.instance_variable_get(:@args)
    end

    def exec_hook(server, result)
      if @hook
        @hook.call(server, result)
        true
      else
        nil
      end
    end

    def self.execute_task(marshal_obj, method_sym, args)
      obj = Marshal.load(marshal_obj)
      obj.__send__(method_sym, *args)
    end

    # DRbQS::Task::TaskSet is a child class of DRbQS::Task and consists of group of a number of tasks.
    # Objects of the class are generated when we set the option :collect to {DRbQS::Task::Generator#set}
    # and therefore we are unaware of the objects of DRbQS::TaskSet in many cases.
    class TaskSet < Task

      # Class to group a number of objects to process tasks.
      class Container
        def initialize(task_ary)
          @data = task_ary.map.with_index do |task, i|
            task.drb_args(i)
          end
        end

        def exec
          @data.map do |ary|
            DRbQS::Task.execute_task(*ary[1..-1])
          end
        end

        def data
          @data
        end
        protected :data

        def ==(other)
          other.data.each_with_index.all? do |ary, i|
            ary == @data[i]
          end
        end
      end

      attr_reader :original_message

      def initialize(task_ary)
        @original_hook = []
        @original_message = []
        task_ary.each do |task|
          @original_hook << task.hook
          @original_message << task.message
        end
        @original_message.compact!
        super(DRbQS::Task::TaskSet::Container.new(task_ary), :exec) do |srv, result|
          result.each_with_index do |res, i|
            if hook = @original_hook[i]
              hook.call(srv, res)
            end
          end
        end
        set_message
      end

      def set_message
        @message = "TaskSet"
        unless @original_message.empty?
          case @original_message.size
          when 1
            @message << ": " << @original_message[0]
          when 2
            @message << ": " << @original_message.join(", ")
          else
            @message << ": " << @original_message[0] << ' - ' << @original_message[-1]
          end
        end
      end
      private :set_message
    end
  end
end
