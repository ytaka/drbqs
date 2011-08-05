require 'drbqs/utility/transfer/transfer_file_list'
require 'drbqs/utility/transfer/transfer'
require 'drbqs/task/registrar'
require 'drbqs/task/task_generator'

module DRbQS

  # The tasks defined by this class are sent to nodes and
  # calculated by the nodes.
  class Task
    attr_reader :obj
    attr_reader :args
    attr_reader :method_name
    attr_reader :hook
    attr_accessor :note

    # Nodes calculate by obj.method_name(*opts[:args]) and send the result to their server.
    # Then the server executes &hook with a server instance and an object of result.
    # For the communication of a server and nodes we must convert obj to a string
    # by Marshal.dump.
    # If we set both opts[:hook] and &hook then &hook is prior to opts[:hook].
    # @param [Object] obj An object that has a method "method_name"
    # @param [Symbol] method_name Method name of calculation
    # @param [Hash] opts The options of tasks.
    # @option opts [Array] :args An array of arguments of method "method_name"
    # @option opts [String] :note Note for a task
    # @option opts [Symbol] :hook Method name for hook
    #  that takes two arguments server and the result object.
    # @param [Proc] hook A server execute hook as a callback when the server receive the result
    #  hook take two arguments: a DRbQS::Server object and a result of task.
    # @note Changes of obj on a node are not sent to a server.
    #  That is, opts[:hook] must not depend on changes of instance variables on a node.
    def initialize(obj, method_name, opts = {}, &hook)
      @obj = obj
      begin
        @marshal_obj = Marshal.dump(@obj)
      rescue
        raise "Can not dump #{@obj.inspect}."
      end
      @method_name = method_name.intern
      @args = opts[:args] || []
      unless Array === @args
        raise "Arguments of task must be an array."
      end
      begin
        @marshal_args = Marshal.dump(@args)
      rescue
        raise "Can not dump #{@args.inspect}."
      end
      @note = opts[:note]
      @hook = hook || opts[:hook]
    end

    def drb_args(task_id)
      [task_id, @marshal_obj, @method_name, @marshal_args]
    end

    def exec_hook(server, result)
      case @hook
      when Proc
        @hook.call(server, result)
      when Symbol, String
        @obj.__send__(@hook, server, result)
      else
        return nil
      end
      true
    end

    def ==(other)
      if @marshal_obj == other.instance_variable_get(:@marshal_obj) &&
          @method_name == other.instance_variable_get(:@method_name) &&
          @marshal_args == other.instance_variable_get(:@marshal_args)
        if Proc === @hook && Proc === other.hook
          # Return false at this time.
          false
        else
          @hook == other.hook
        end
      else
        false
      end
    end

    def self.call_task_method(obj, method_name, args)
      obj.__send__(method_name, *args)
    end

    def self.execute_task(marshal_obj, method_name, marshal_args)
      self.call_task_method(Marshal.load(marshal_obj), method_name, Marshal.load(marshal_args))
    end

    # DRbQS::Task::TaskSet is a child class of DRbQS::Task and consists of group of a number of tasks.
    # Objects of the class are generated when we set the option :collect to {DRbQS::Task::Generator#set}
    # and therefore we are unaware of the objects of DRbQS::TaskSet in many cases.
    class TaskSet < Task

      class Container
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

      class ContainerTask < DRbQS::Task::TaskSet::Container
        def initialize(task_ary)
          @data = task_ary
        end

        def exec
          @data.map do |task|
            DRbQS::Task.call_task_method(task.obj, task.method_name, task.args)
          end
        end

        def exec_all_hooks(srv, result)
          result.each_with_index do |res, i|
            @data[i].exec_hook(srv, res)
          end
        end
      end

      # Class to group a number of objects to process tasks.
      class ContainerWithoutHook < DRbQS::Task::TaskSet::Container
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
      end

      attr_reader :original_note

      def initialize(task_ary)
        @original_note = task_ary.map do |task|
          task.note
        end.compact!
        if task_ary.all? { |task| !(Proc === task.hook) }
          container = DRbQS::Task::TaskSet::ContainerTask.new(task_ary)
          super(container, :exec, hook: :exec_all_hooks, note: note_string)
        else
          container = DRbQS::Task::TaskSet::ContainerWithoutHook.new(task_ary)
          @original_task = task_ary
          super(container, :exec, note: note_string) do |srv, result|
            result.each_with_index do |res, i|
              @original_task[i].exec_hook(srv, res)
            end
          end
        end
      end

      def note_string
        str = "TaskSet"
        unless @original_note.empty?
          case @original_note.size
          when 1
            str << ": " << @original_note[0]
          when 2
            str << ": " << @original_note.join(", ")
          else
            str << ": " << @original_note[0] << ' - ' << @original_note[-1]
          end
        end
        str
      end
      private :note_string
    end
  end
end
