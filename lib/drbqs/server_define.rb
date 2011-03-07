module DRbQS

  class ServerDefinition
    HELP_MESSAGE =<<HELP
[Server specific options]
  These options are separated by '--' from command options.

HELP

    def initialize
      @server_create = nil
      @option_parse = nil
      @opts = {}
      @argv = nil
    end

    def define_server(&block)
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

    def start_server(options)
      unless @server_create
        raise "Can not get server definition."
      end
      server = DRbQS::Server.new(options)
      @server_create.call(server, @argv, @opts)
      server.set_signal_trap
      server.start
      server.wait
    end
  end

  @@server_def = ServerDefinition.new

  def self.define_server(&block)
    @@server_def.define_server(&block)
  end

  def self.option_parser(&block)
    @@server_def.option_parser(&block)
  end

  def self.parse_option(opt_argv)
    @@server_def.parse_option(opt_argv)
  end

  def self.start_server(options)
    @@server_def.start_server(options)
  end
end
