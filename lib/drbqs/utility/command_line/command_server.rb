module DRbQS
  class Command
    class Server < DRbQS::Command::Base
      @@command_name = File.basename($PROGRAM_NAME)

      HELP_MESSAGE =<<HELP
Usage: #{@@command_name} <definition.rb> [other files ...] [options ...]
       #{@@command_name} <definition.rb> [other files ...] [options ...] -- [server options ...]
  Start DRbQS server of definition files.

HELP

      NODE_INTERVAL_TIME = 1

      def parse_option(argv)
        @options = {
          :log_file => STDOUT,
          :log_level => Logger::ERROR
        }
        @command_type = :server_start

        @test_opts = {}
        @execute_node_number = nil
        @command_argv, @server_argv = split_arguments(argv)

        @command_argv = option_parser_base(@command_argv, HELP_MESSAGE, :daemon => true, :debug => true) do |opt|
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
            @options[:log_level] = parse_log_level(v)
          end
          opt.on('--file-directory DIR', String, 'Set the file archive directory.') do |v|
            @options[:file_directory] = v
          end
          opt.on('--sftp-user USER', String, 'Set the user of sftp destination.') do |v|
            @options[:sftp_user] = v
          end
          opt.on('--sftp-host HOST', String, 'Set the host of sftp destination.') do |v|
            @options[:sftp_host] = v
          end
          opt.on('--profile', 'Use profile for test exec.') do |v|
            @test_opts[:profile] = true
          end
          opt.on('--profile-printer PRINTER', String,
                 'Set the printer type for profile. The value is :flat, :graph, :graphhtml, or :calltree.') do |v|
            @test_opts[:printer] = v.intern
          end
          opt.on('--test STR', String, 'Execute test.') do |v|
            @command_type = "test_#{v}"
          end
          opt.on('--execute-node NUM', Integer, 'Execute nodes.') do |v|
            @execute_node_number = v
          end
          opt.on('-h', '--help', 'Show this command help and server specific help.') do |v|
            $stdout.print opt
            @command_type = :help
          end
        end
      end

      def command_test
        args = @command_type.split('_')[1].split(',')
        type = args.shift.intern
        limit = args[0] ? args[0].to_i : nil
        server = DRbQS.create_test_server(@options)
        case type
        when :task
          $stdout.puts "*** Test of Task Generators ***"
          server.test_task_generator(:limit => limit, :progress => true)
        when :exec
          data = server.test_exec(:limit => limit, :profile => @test_opts[:profile], :printer => @test_opts[:printer])
          s = sprintf("Results: %d tasks; total %.4fs", data[:task], data[:end] - data[:start])
          s << sprintf("; %.4fs per one task", (data[:end] - data[:start]) / data[:task]) if data[:task] > 0
          s << "\nOutput the profile data to #{data[:profile]}" if data[:profile]
          $stdout.puts s
        else
          $stdout.puts "error: Not yet implemented test '#{type}'"
          exit_invalid_option
        end
      end
      private :command_test

      def command_start_server
        DRbQS.start_server(@options)
      end
      private :command_start_server

      def current_server_uri
        DRbQS::Misc.create_uri(@options)
      end
      private :current_server_uri

      def wait_server_process(uri, server_pid = nil)
        manage = DRbQS::Manage.new(:uri => uri)
        manage.wait_server_process(server_pid)
      rescue DRbQS::Manage::NoServerRespond => err
        $stderr.puts err.to_s
        nil
      end
      private :wait_server_process

      def execute_node_and_wait(uri)
        node_log_file = nil
        unless IO === @options[:log_file]
          node_log_file = FileName.create(@options[:log_file], :add => :always, :position => :middle, :delimiter => '', :format => "_node_%02d")
        end
        exec_node = DRbQS::ExecuteNode.new(uri, node_log_file, @options[:log_level])
        exec_node.execute(@execute_node_number, NODE_INTERVAL_TIME)
        exec_node.wait
      end
      private :execute_node_and_wait

      def command_server_with_nodes
        server_pid = fork do
          DRbQS.start_server(@options)
        end
        uri = current_server_uri
        if wait_server_process(uri, server_pid)
          execute_node_and_wait(uri)
        else
          $stderr.puts "error: Probably, the server of #{uri} can not be executed properly."
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

      def setup_arguments
        @command_argv.each do |path|
          load path
        end
        unless @options[:acl]
          @options[:acl] = DRbQS::Config.new.get_acl_file
        end
        DRbQS.parse_option(@server_argv)
      end
      private :setup_arguments

      def exec_normally
        setup_arguments
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
      end
      private :exec_normally

      def fork_daemon_process
        if @daemon
          case @command_type
          when /^test/
            $stderr.puts "Command '#{@command_type}' does not support daemon"
            setup_arguments
            command_test
          else
            fork do
              exec_as_daemon
            end
            uri = current_server_uri
            if wait_server_process(uri)
              exit_normally
            else
              $stderr.puts "error: Probably, the server of #{uri} can not be executed properly."
              exit_unusually
            end
          end
        end
      end
      private :fork_daemon_process

      def exec
        if @command_type == :help
          command_server_help
        elsif @command_argv.size == 0
          $stderr.print "error: Files for server definition are specified.\n\n" << HELP_MESSAGE
          exit_unusually
        elsif !(@command_argv.all? { |path| File.exist?(path) })
          $stderr.print "error: There are nonexistent files.\n\n" << HELP_MESSAGE
          exit_unusually
        else
          fork_daemon_process
        end
        exec_normally
      rescue => err
        $stderr.print "error: #{err.to_s}\n" << err.backtrace.join("\n")
        exit_unusually
      end
    end
  end
end
