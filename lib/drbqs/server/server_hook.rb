module DRbQS
  class Server
    class Hook
      def initialize
        @hook = Hash.new { |h, k| h[k] = Array.new }
        @argument_number = {}
        @finish_exit = nil
        set_argument_number(:empty_queue, 1)
        set_argument_number(:process_data, 2)
        set_argument_number(:finish, 1)
        set_argument_number(:task_assigned, 1)
      end

      def set_argument_number(key, num)
        @argument_number[key] = num
      end
      private :set_argument_number

      def create_proc_name(key)
        name = "#{key.to_s}#{rand(1000)}"
        if @hook.has_key?(name)
          create_proc_name(key)
        else
          name
        end
      end
      private :create_proc_name

      def add(key, opts = {}, &block)
        unless block_given?
          raise ArgumentError, "The main part of hook must be specified as a block."
        end
        if (n = @argument_number[key]) && (block.arity != n)
          raise ArgumentError, "Invalid argument number of hook of #{key.inspect}."
        end
        name = opts[:name] || create_proc_name(key)
        @hook[key] << [name, block, opts[:repeat]]
        name
      end

      def delete(key, name = nil)
        if name
          @hook[key].delete_if { |ary| ary[0] == name }
        else
          @hook[key].clear
        end
      end

      def specific_proc(key, &cond)
        case key
        when :finish
          if @finish_exit
            if !cond || cond.call('special:finish_exit')
              @finish_exit.call
            end
          end
        when :task_assigned
          if @shutdown_unused_nodes
            if !cond || cond.call('special:task_assigned')
              @shutdown_unused_nodes.call
            end
          end
        end
      end
      private :specific_proc

      def hook_names(key)
        @hook[key].map { |a| a[0] }
      end

      def delete_unused_hook
        @hook.keys.each do |key|
          @hook[key].delete_if do |ary|
            ary[2] && ary[2] == 0
          end
        end
      end
      private :delete_unused_hook

      def exec(key, *args, &cond)
        delete_unused_hook
        @hook[key].each do |ary|
          name, proc, repeat = ary
          if !cond || cond.call(name)
            if !repeat || repeat > 0
              proc.call(*args)
              ary[2] -= 1 if repeat
            end
          else
            return nil
          end
        end
        specific_proc(key, &cond)
      end

      def set_finish_exit(&block)
        @finish_exit = block
      end

      def set_shutdown_unused_nodes(&block)
        @shutdown_unused_nodes = block
      end

      def number_of_hook(key)
        @hook.has_key?(key) ? @hook[key].size : 0
      end
    end
  end
end
