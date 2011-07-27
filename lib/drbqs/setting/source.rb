module DRbQS
  class Setting
    class InvalidArgument < StandardError
    end

    class Source
      attr_reader :value, :default

      def initialize(all_keys_defined = true)
        @cond = {}
        @default = {}
        @value = DRbQS::Setting::Source::DataContainer.new(Array)
        @argument_condition = nil
        @all_keys_defined = all_keys_defined
      end

      def clone
        new_obj = self.class.new(!!@all_keys_defined)
        args = [@cond.clone, @default.clone, DRbQS::Setting::Source.clone_container(@value), @argument_condition]
        new_obj.instance_exec(*args) do |cond, default, value, arg_cond|
          @cond = cond
          @default = default
          @value = value
          @argument_condition = arg_cond
        end
        new_obj
      end

      # For debug.
      def registered_keys
        @cond.keys
      end

      def registered_key?(key)
        @cond.has_key?(key)
      end
      private :registered_key?

      def boolean_value?(key)
        registered_key?(key) && @cond[key][:bool]
      end
      private :boolean_value?

      def value_to_add?(key)
        registered_key?(key) && @cond[key][:add]
      end
      private :value_to_add?

      def check_argument_array_size(check, args, target = nil)
        n = args.size
        check.each_slice(2).each do |ary|
          unless n.__send__(*ary)
            mes = "Size"
            if target
              mes << " of #{target.inspect}"
            end
            mes << " must be " << ary.map(&:to_s).join(' ') << ", but #{n}"
            raise DRbQS::Setting::InvalidArgument, mes
          end
        end
      end
      private :check_argument_array_size

      def check!
        if @argument_condition
          check_argument_array_size(@argument_condition, get_argument, "argument array")
        end
        keys = @value.__data__.keys
        keys.each do |key|
          args = @value.__data__[key]
          unless Symbol === key
            key = key.intern
            @value.__data__.delete(key)
          end
          if registered_key?(key)
            if check = @cond[key][:check]
              check_argument_array_size(check, args, key)
            end
          elsif @all_keys_defined
            raise DRbQS::Setting::InvalidArgument, "Undefined key '#{key.inspect}' must not set."
          end
          if boolean_value?(key)
            @value.__data__[key] = [(args.size == 0 || args[0] ? true : false)]
          else
            @value.__data__[key] = args
          end
        end
      end

      def parse_condition(check)
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
      private :parse_condition

      # :check
      # :add
      # :bool
      # :default
      def register_key(key, opts = {})
        k = key.intern
        if registered_key?(k)
          @cond[k].clear
        else
          @cond[k] = {}
        end
        if check = opts[:check]
          @cond[k][:check] = parse_condition(check)
        end
        if default = opts[:default]
          check_argument_array_size(@cond[k][:check], default, "default of #{k.inspect}") if @cond[k][:check]
          @default[k] = default
        end
        @cond[k][:add] = opts[:add]
        @cond[k][:bool] = opts[:bool]
      end

      def set_argument_condition(*checks)
        @argument_condition = parse_condition(checks)
      end

      def set(key, *args)
        k = key.intern
        if value_to_add?(key) && @value.__data__[k]
          @value.__data__[k].concat(args)
        else
          @value.__data__[k] = args
        end
      end

      def clear(key)
        @value.__data__.delete(key.intern)
      end

      def get(key, &block)
        k = key.intern
        val = @value.__data__[k] || @default[k]
        if block_given? && val
          yield(val)
        else
          val
        end
      end

      def get_first(key, &block)
        val = get(key) do |ary|
          ary[0]
        end
        block_given? && val ? yield(val) : val
      end

      def set?(key)
        !!@value.__data__[key.intern]
      end

      def set_argument(*args)
        @value.argument = args
      end

      def get_argument
        @value.argument
      end

      def escape_string_for_shell(str)
        '"' << str.gsub(/"/, '\"') << '"'
      end
      private :escape_string_for_shell

      def argument_array_for_command_line(escape)
        ary = get_argument.map do |val|
          val.to_s
        end
        if escape
          ary.map! do |val|
            escape_string_for_shell(val)
          end
        end
        ary
      end
      private :argument_array_for_command_line

      def option_array_for_command_line(escape)
        ary = []
        @value.__data__.each do |k, val|
          s = k.to_s
          s.strip!
          if s.size > 0
            option_key = (s.size == 1 ? "-#{s}" : "--#{s}")
            option_key.gsub!(/_/, '-')
            if !@cond[k][:bool]
              val.each do |v|
                ary << option_key
                value_string = v.to_s
                if escape
                  value_string = escape_string_for_shell(value_string)
                end
                ary << value_string
              end
            elsif val
              ary << option_key
            end
          end
        end
        ary
      end
      private :option_array_for_command_line

      def command_line_argument(escape = nil)
        argument_array_for_command_line(escape) + option_array_for_command_line(escape)
      end
    end
  end
end
