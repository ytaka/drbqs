module DRbQS
  class Setting
    class InvalidArgument < StandardError
    end

    class Source
      class DataContainer < BasicObject
        attr_accessor :argument
        attr_reader :__data__

        def initialize(array_class)
          @argument = []
          @__data__ = {}
          @__array__ = array_class
        end

        def method_missing(name, *args)
          if /=$/ =~ name.to_s
            if @__array__ === args[0]
              @__data__[name.to_s[0...-1].intern] = args[0]
            else
              @__data__[name.to_s[0...-1].intern] = args
            end
          else
            @__data__[name]
          end
        end
      end

      attr_reader :value, :default

      def initialize(all_keys_defined = true)
        @check = {}
        @add = {}
        @bool = {}
        @default = {}
        @value = DRbQS::Setting::Source::DataContainer.new(Array)
        @argument_condition = nil
        @all_keys_defined = all_keys_defined
      end

      def check!
        if @argument_condition
          checking(@argument_condition, get_argument)
        end
        keys = @value.__data__.keys
        keys.each do |key|
          args = @value.__data__[key]
          unless Symbol === key
            key = key.intern
            @value.__data__.delete(key)
          end
          check_argument_size(key, args)
          if @bool[key]
            @value.__data__[key] = (args.size == 0 || args[0] ? true : false)
          elsif @all_keys_defined && !@add.has_key?(key)
            raise DRbQS::Setting::InvalidArgument, "Undefined key #{k.inspect}"
          else
            @value.__data__[key] = args
          end
        end
      end

      def checking(check, args, key = nil)
        n = args.size
        check.each_slice(2).each do |ary|
          unless n.__send__(*ary)
            if key
              mes = "Invalid argument for #{key.inspect}"
            else
              mes = "Invalid argument"
            end
            raise DRbQS::Setting::InvalidArgument, mes
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
          raise DRbQS::Setting::InvalidArgument, "Invalid argument condition."
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
        if @add[k] && @value.__data__[k]
          @value.__data__[k].concat(args)
        else
          @value.__data__[k] = args
        end
      end

      def clear(key)
        k = key.intern
        @add.delete(k)
        @value.__data__.delete(k)
      end

      def get(key, &block)
        k = key.intern
        val = @value.__data__[k] || @default[k] || (@add[k] ? [] : nil)
        if block_given? && val
          yield(val)
        else
          val
        end
      end

      def get_first(key, &block)
        k = key.intern
        ary = @value.__data__[k] || @default[k] || (@add[k] ? [] : nil)
        val = (Array === ary ? ary[0] : ary)
        if block_given? && val
          yield(val)
        else
          val
        end
      end

      def set_argument(*args)
        @value.argument = args
      end

      def get_argument
        @value.argument
      end

      def command_line_argument(escape = nil)
        ary = get_argument
        @value.__data__.each do |k, val|
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

      def [](key)
        get(key)
      end

      def []=(key, args)
        set(key, *args)
      end
    end
  end
end
