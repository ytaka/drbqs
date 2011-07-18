module DRbQS
  class CommandServer < CommandBase
    @@command_name = File.basename($PROGRAM_NAME)

    HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition.rb> [other files ...] [options ...]
       #{@@command_name} <definition.rb> [other files ...] [options ...] -- [server options ...]
  Start DRbQS server of definition files.

HELP

    NODE_INTERVAL_TIME = 1

    def parse_option(argv)
      @options = {
        :log_file => STDOUT
      }
      @command_type = :server_start

      test_opts = {}
      @execute_node_number = nil
      @command_argv, @server_argv = split_arguments(argv)

      begin
        OptionParser.new(HELP_MESSAGE) do |opt|
          opt.on('-p PORT', '--port', Integer, 'Set the port number of server.') do |v|
            @options[:port] = v
          end
          opt.on('-u PATH', '--unix', String, 'Set the path of unix domain socket.') do |v|
            @options[:unix] = v
          end
          opt.on('--acl FILE', String, 'Set a file to define ACL.') do |v|
            @options[:acl] = v
          end
          opt.on('--log-file STR', String, "Set the path of log file. If this options is not set, use STDOUT.") do |v|
            @options[:log_file] = v
          end
          opt.on('--log-level LEVEL', String,
                 "Set the log level. The value accepts 'fatal', 'error', 'warn', 'info', and 'debug'. The default is 'error'.") do |v|
            if /^(fatal)|(error)|(warn)|(info)|(debug)$/i =~ v
              @options[:log_level] = eval("Logger::#{v.upcase}")
            else
              $stderr.print "error: Invalid log level.\n\n" << HELP_MESSAGE
              exit_invalid_option
            end
          end
          opt.on('--file-directory DIR', String, 'Set the file archive directory.') do |v|
            @options[:file_directory] = v
          end
          opt.on('--scp-user USER', String, 'Set the user of scp destination.') do |v|
            @options[:scp_user] = v
          end
          opt.on('--scp-host HOST', String, 'Set the host of scp destination.') do |v|
            @options[:scp_host] = v
          end
          opt.on('--profile', 'Use profile for test exec.') do |v|
            @test_opts[:profile] = true
          end
          opt.on('--debug', 'Set $DEBUG true.') do |v|
            $DEBUG = true
          end
          opt.on('--test STR', String, 'Execute test.') do |v|
            @command_type = "test_#{v}"
          end
          opt.on('--execute-node NUM', Integer, 'Execute nodes.') do |v|
            @execute_node_number = v
          end
          opt.on('-h', '--help', 'Show help.') do |v|
            $stdout.print opt
            @command_type = :help
          end
          opt.parse!(@command_argv)
        end
      rescue OptionParser::InvalidOption
        $stderr.print "error: Invalid Option\n\n" << HELP_MESSAGE
        exit_invalid_option
      rescue OptionParser::InvalidArgument
        $stderr.print "error: Invalid Argument\n\n" << HELP_MESSAGE
        exit_invalid_option
      end
    end

    def command_test
      s = @command_type.split('_')[1].split(',')
      type = s[0].intern
      DRbQS.test_server(@options, type, s[1..-1], @test_opts)
    end
    private :command_test

    def command_start_server
      DRbQS.start_server(@options)
    end
    private :command_start_server

    def command_server_with_nodes
      server_pid = fork do
        DRbQS.start_server(@options)
      end
      uri = DRbQS::Misc.create_uri(@options)
      manage = DRbQS::Manage.new(:uri => uri)
      if manage.wait_server_process(server_pid)
        node_log_file = nil
        unless IO === @options[:log_file]
          node_log_file = FileName.create(@options[:log_file], :add => :always, :position => :middle, :delimiter => '', :format => "_node_%02d")
        end
        exec_node = DRbQS::ExecuteNode.new(uri, node_log_file, @options[:log_level])
        exec_node.execute(@execute_node_number, NODE_INTERVAL_TIME)
        exec_node.wait
      else
        $stderr.puts "error: Server has been terminated."
        exit_unusually
      end
    end
    private :command_server_with_nodes

    def command_server_help
      begin
        @command_argv.each do |path|
          if File.exist?(path)
            load path
          end
        end
        if mes = DRbQS.option_help_message
          $stdout.print "\n" << mes
        end
      rescue => err
        $stderr.print "error: Load invalid file.\n#{err.to_s}\n#{err.backtrace.join("\n")}"
        exit_invalid_option
      end
      exit_normally
    end
    private :command_server_help

    def exec
      if @command_type == :help
        command_server_help
      end
      if @command_argv.size == 0 || !(@command_argv.all? { |path| File.exist?(path) })
        $stderr.print "error: There are nonexistent files.\n\n" << HELP_MESSAGE
        exit_unusually
      end
      @command_argv.each do |path|
        load path
      end
      unless @options[:acl]
        @options[:acl] = DRbQS::Config.new.get_acl_file
      end
      DRbQS.parse_option(@server_argv)
      case @command_type
      when /^test/
        command_test
      else
        if @execute_node_number
          command_server_with_nodes
        else
          command_start_server
        end
      end
      exit_normally
    rescue => err
      $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
      exit_unusually
    end
  end
end
