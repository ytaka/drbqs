module DRbQS
  class Setting
    class Server < DRbQS::Setting::Base
      NODE_INTERVAL_TIME = 1

      def initialize
        super(:all_keys_defined => true, :log_level => true, :daemon => true) do
          [:port, :unix, :acl, :sftp_user, :sftp_host,
           :profile_printer, :test, :execute_node].each do |key|
            register_key(key, :check => 1)
          end
          register_key(:log_file, :check => 1, :default => [STDOUT])
          register_key(:profile, :bool => true)
          register_key(:help, :bool => true)

          set_argument_condition(:>, 0)
        end

        @server_argument = DRbQS::Setting::Source.new(nil)

        @command_type = :server_start
        @test_opts = {}
        @execute_node_number = nil
      end

      def parse_test
        @test_opts[:profile] = get(:profile)
        @test_opts[:printer] = get_first(:printer) do |val|
          val.intern
        end
        if test = get_first(:test)
          @command_type = "test_#{test.to_s}"
        end
      end
      private :parse_test

      def parse_execute_node
        @execute_node_number = get_first(:execute_node) do |val|
          val.to_i
        end
      end
      private :parse_execute_node

      def parse_command_argument
        get_argument.each do |path|
          unless File.exist?(path)
            raise ArgumentError, "#{path} does not exist."
          end
        end
      end
      private :parse_command_argument

      def parse!
        if get(:help)
          @command_type = :help
          return true
        end
        super
        parse_test
        parse_execute_node
        @options[:port] = get_first(:port) do |val|
          val.to_i
        end
        @options[:unix] = get_first(:unix)
        @options[:acl] = get_first(:acl)
        @options[:sftp_user] = get_first(:sftp_user)
        @options[:sftp_host] = get_first(:sftp_host)
        @options[:log_file] = get_first(:log_file)
      end

      def set_server_argument(*args)
        @server_argument.set_argument(*args)
      end

      def command_line_argument(escape = nil)
        ary = super(escape)
        server_args = @server_argument.command_line_argument(escape)
        if server_args.size > 0
          ary << '--'
          ary.concat(server_args)
        end
        ary
      end

      def command_test(io)
        args = @command_type.split('_')[1].split(',')
        type = args.shift.intern
        limit = args[0] ? args[0].to_i : nil
        server = DRbQS.create_test_server(@options)
        case type
        when :task
          server.test_task_generator(:limit => limit, :progress => true)
        when :exec
          data = server.test_exec(:limit => limit, :profile => @test_opts[:profile], :printer => @test_opts[:printer])
          if io
            s = sprintf("Results: %d tasks; total %.4fs", data[:task], data[:end] - data[:start])
            s << sprintf("; %.4fs per one task", (data[:end] - data[:start]) / data[:task]) if data[:task] > 0
            s << "\nOutput the profile data to #{data[:profile]}" if data[:profile]
            io.puts s
          end
        else
          raise ArgumentError, "Not yet implemented test '#{type}'"
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
          raise "Probably, the server of #{uri} can not be executed properly."
        end
      end
      private :command_server_with_nodes

      def command_server_help(io)
        if io
          begin
            get_argument.each do |path|
              if File.exist?(path)
                load path
              end
            end
            if mes = DRbQS.option_help_message
              io.print "\n" << mes
            end
          rescue
            raise
          end
        end
      end
      private :command_server_help

      def setup_arguments
        get_argument.each do |path|
          load path
        end
        unless @options[:acl]
          @options[:acl] = DRbQS::Config.new.get_acl_file
        end
        DRbQS.parse_option(@server_argument.get_argument)
      end
      private :setup_arguments

      def fork_daemon_process
        if @__daemon__
          case @command_type
          when /^test/
            raise ArgumentError, "Test of server does not support daemon"
          else
            fork do
              exec_as_daemon
            end
            uri = current_server_uri
            unless wait_server_process(uri)
              raise "Probably, the server of #{uri} can not be executed properly."
            end
          end
          true
        else
          nil
        end
      end
      private :fork_daemon_process

      def exec(io = nil)
        if @command_type == :help
          command_server_help(io)
        elsif !fork_daemon_process
          setup_arguments
          case @command_type
          when /^test/
            command_test(io)
          else
            if @execute_node_number
              command_server_with_nodes
            else
              command_start_server
            end
          end
        end
        true
      end
    end
  end
end
