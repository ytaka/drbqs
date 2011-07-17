module DRbQS

  class ServerDefinition
    HELP_MESSAGE =<<HELP
* Server specific options
  These options are separated by '--' from command options.

HELP

    def initialize
      @server_create = nil
      @option_parse = nil
      @opts = {}
      @argv = nil
      @default_server_opts = nil
    end

    def define_server(default_opts = {}, &block)
      @default_server_opts = default_opts
      if @server_create
        raise ArgumentError, "The server has already defined."
      end
      @server_create = block
    end

    def option_parser(&block)
      if @option_parse
        raise ArgumentError, "The options parser has already defined."
      end
      @option_parse = block
    end

    def parse_option(opt_argv)
      if @option_parse
        OptionParser.new(HELP_MESSAGE) do |opt|
          @option_parse.call(opt, @opts)
          opt.parse!(opt_argv)
        end
      end
      @argv = opt_argv  
    end

    def option_help_message
      if @option_parse
        OptionParser.new(HELP_MESSAGE) do |opt|
          @option_parse.call(opt, @opts)
          return opt.to_s
        end
      else
        nil
      end
    end

    def create_server(options)
      server = DRbQS::Server.new(@default_server_opts.merge(options))
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

    def test_server(options, type, arg = [], test_opts = {})
      server = create_server(options)
      case type
      when :task
        puts "*** Test of Task Generators ***"
        server.test_task_generator(:limit => arg[0] ? arg[0].to_i : nil, :progress => true)
      when :exec
        server.test_exec(:limit => arg[0] ? arg[0].to_i : nil, :profile => test_opts[:profile])
      else
        puts "*** Not be yet implemented ***"
      end
    end
  end

  @@server_def = ServerDefinition.new

  class << self
    [:define_server, :option_parser, :parse_option, :option_help_message,
     :start_server, :test_server].each do |m|
      define_method(m, &@@server_def.method(m))
    end
  end
end
