require 'forwardable'

module DRbQS
  class Setting
    class InvalidLogLevel < StandardError
    end

    LOG_LEVEL_DEFAULT = Logger::ERROR

    # A base class having options of commands.
    # We must define a method 'exec' this method in a child class.
    class Base
      extend Forwardable

      attr_reader :source

      # The keys of options are :all_keys_defined, :log_level, and :daemon
      def initialize(opts = {}, &block)
        @source = DRbQS::Setting::Source.new(opts[:all_keys_defined])
        @source.register_key(:debug, :bool => true)
        if opts[:log_level]
          @source.register_key(:log_level, :check => 1, :default => [Logger::ERROR])
        end
        if opts[:daemon]
          @__daemon__ = nil
          @source.register_key(:daemon, :check => 1)
        end
        @source.instance_eval(&block) if block_given?
        @options = {}
      end

      def_delegator :@source, :set, :set
      def_delegator :@source, :get, :get
      def_delegator :@source, :clear, :clear
      def_delegator :@source, :set?, :set?
      def_delegator :@source, :get_first, :get_first
      def_delegator :@source, :set_argument, :set_argument
      def_delegator :@source, :get_argument, :get_argument
      def_delegator :@source, :command_line_argument, :command_line_argument
      def_delegator :@source, :default, :default

      def string_for_shell
        command_line_argument(true).join(" ")
      end

      def value
        @source.value
      end

      def clone
        new_obj = self.class.new
        instance_variables.each do |var_name|
          var = instance_variable_get(var_name)
          case var
          when NilClass, FalseClass, TrueClass, Symbol
            new_var = var
          else
            new_var = var.clone
          end
          new_obj.instance_variable_set(var_name, new_var)
        end
        new_obj
      end

      def preprocess!
      end
      private :preprocess!

      # We execute DRbQS::Setting::Base#parse! before execute 'exec'.
      def parse!
        preprocess!
        @source.check!
        $DEBUG = true if get_first(:debug)
        @__daemon__ = get_first(:daemon)
        parse_log_level
      end

      def parse_log_level
        if arg = get_first(:log_level)
          case arg
          when /^(fatal)|(error)|(warn)|(info)|(debug)|(unknown)$/i
            n = eval("Logger::#{arg.upcase}")
            unless 0 <= n && n <= 5
              raise DRbQS::Setting::InvalidLogLevel, "error: Invalid log level '#{arg}'"
            end
          when /^[0-5]$/
            n = arg.to_i
          when 0..5
            n = arg
          else
            raise DRbQS::Setting::InvalidLogLevel, "error: Invalid log level '#{arg}'"
          end
          @options[:log_level] = n
        end
      end
      private :parse_log_level

      def daemon_start(output, &block)
        Process.daemon(true)
        begin
          $stdout = Kernel.open(output, 'w')
          $stderr = $stdout
          begin
            yield
          rescue SystemExit
            return true
          end
        rescue Exception => err
          output_error(err)
        ensure
          $stdout.close
        end
      end
      private :daemon_start

      def exec_as_daemon(&block)
        if @__daemon__
          @__daemon__ = FileName.create(@__daemon__, :position => :middle, :type => :time, :directory => :parent)
          daemon_start(@__daemon__) do
            @__daemon__ = nil
            if block_given?
              yield
            else
              exec($stdout)
            end
          end
          true
        else
          nil
        end
      end
      private :exec_as_daemon
    end
  end
end
