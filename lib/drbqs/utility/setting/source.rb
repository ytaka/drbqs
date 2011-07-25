module DRbQS
  class Setting
    class Source
      def initialize(all_keys_defined = true)
        @check = {}
        @add = {}
        @bool = {}
        @default = {}
        @value = {}
        @argument = nil
        @argument_condition = nil
        @all_keys_defined = all_keys_defined
      end

      def checking(check, args)
        n = args.size
        check.each_slice(2).each do |ary|
          unless n.__send__(*ary)
            raise ArgumentError, "Invalid arguments number. Please refer to documents."
          end
        end
      end
      private :checking

      def check_argument_size(key, args)
        if !@bool[key] && (check = @check[key])
          checking(check, args)
        end
        true
      end
      private :check_argument_size

      def condition(check)
        if Fixnum === check
          [:==, check]
        elsif check.size == 1 && Fixnum === check[0]
          [:==, check[0]]
        elsif Array === check && check.size.even?
          check
        else
          raise ArgumentError, "Invalid argument to check array size."
        end
      end
      private :condition

      # :check
      # :add
      # :bool
      # :default
      def register_key(key, opts = {})
        k = key.intern
        if check = opts[:check]
          @check[k] = condition(check)
        end
        if default = opts[:default]
          checking(@check[k], default) if @check[k]
          @default[k] = default
        end
        @add[k] = opts[:add]
        @bool[k] = opts[:bool]
      end

      def set_argument_condition(*checks)
        @argument_condition = condition(checks)
      end

      def set(key, *args)
        k = key.intern
        check_argument_size(k, args)
        if @bool[k]
          @value[k] = (args.size == 0 || args[0] ? true : false)
        elsif @add[k] && @value[k]
          @value[k].concat(args)
        elsif @all_keys_defined && !@add.has_key?(k)
          raise ArgumentError, "Undefined key #{k.inspect}"
        else
          @value[k] = args
        end
      end

      def clear(key)
        k = key.intern
        @add.delete(k)
        @value.delete(k)
      end

      def get(key, &block)
        k = key.intern
        val = @value[k] || @default[k] || (@add[k] ? [] : nil)
        if block_given? && val
          yield(val)
        else
          val
        end
      end

      def get_first(key, &block)
        k = key.intern
        ary = @value[k] || @default[k] || (@add[k] ? [] : nil)
        val = (Array === ary ? ary[0] : ary)
        if block_given? && val
          yield(val)
        else
          val
        end
      end

      def set_argument(*args)
        @argument = args
      end

      def get_argument
        @argument ? @argument.dup : []
      end

      def check_argument
        if @argument_condition
          checking(@argument_condition, get_argument)
        end
      end

      def command_line_argument(escape = nil)
        ary = get_argument
        @value.each do |k, val|
          s = k.to_s
          option_key = (s.size == 1 ? "-#{s}" : "--#{s}").gsub!(/_/, '-')
          if !@bool[k]
            val.each do |v|
              ary << option_key
              value_string = v.to_s
              if escape
                value_string = '"' << value_string.gsub(/"/, '\"') << '"'
              end
              ary << value_string
            end
          elsif val
            ary << option_key
          end
        end
        ary
      end
    end
  end
end
