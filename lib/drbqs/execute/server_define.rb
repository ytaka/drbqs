module DRbQS
  class Execution
    class ServerDefinition
      HELP_MESSAGE =<<HELP
* Server specific options
  These options are separated by '--' from command options.

HELP

      def initialize
        clear_definition
      end

      def define_server(default_opts = {}, &block)
        @default_server_opts = default_opts
        if @server_create
          raise ArgumentError, "The server has already defined."
        end
        @server_create = block
      end

      def option_parser(mes = nil, &block)
        if @option_parse
          raise ArgumentError, "The options parser has already defined."
        end
        @option_message = mes
        @option_parse = block
      end

      def create_parser(&block)
        mes = HELP_MESSAGE
        mes += @option_message.gsub(/(^\n+)|(\n+$)/, '') + "\n\n" if @option_message
        OptionParser.new(mes) do |opt|
          yield(opt)
        end
      end
      private :create_parser

      def parse_option(opt_argv)
        if @option_parse
          create_parser do |opt|
            @option_parse.call(opt, @opts)
            opt.parse!(opt_argv)
          end
        end
        @argv = opt_argv  
      end

      def option_help_message
        if @option_parse
          create_parser do |opt|
            @option_parse.call(opt, @opts)
            return opt.to_s
          end
        else
          nil
        end
      end

      def clear_definition
        @server_create = nil
        @option_parse = nil
        @opts = {}
        @argv = nil
        @default_server_opts = nil
      end

      def create_server(options, klass = DRbQS::Server)
        server = klass.new(@default_server_opts.merge(options))
        @server_create.call(server, @argv, @opts)
        server.set_signal_trap
        server
      end
      private :create_server

      def start_server(options)
        unless @server_create
          raise "Can not get server definition."
        end
        server = create_server(options)
        server.start
        server.wait
      end

      def create_test_server(options)
        require 'drbqs/server/test/server'
        options.delete(:not_exit)
        create_server(options, DRbQS::Test::Server)
      end
    end
  end

  @@server_def = DRbQS::Execution::ServerDefinition.new

  class << self
    [:define_server, :option_parser, :parse_option, :option_help_message, :clear_definition,
     :start_server, :create_test_server].each do |m|
      define_method(m, &@@server_def.method(m))
    end
  end
end
