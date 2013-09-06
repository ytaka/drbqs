module DRbQS
  class ProcessDefinition
    class Register
      # @return [Array] an array of pair [name symbol, definition hash]
      # Keys of the hash are :type, :template, :ssh, :setting, and :args.
      attr_reader :__server__, :__node__

      # @return [Array] a hash of key and value
      attr_reader :__default__, :__usage__

      def initialize
        @__server__ = []
        @__node__ = []
        @__default__ = {}
        @__usage__ = {}
      end

      def __register__(type, setting, name, template, args, &block)
        ary = [name.intern, { :type => type.intern, :template => template, :args => args }]
        type = type.to_s
        # Note that if type is :server, then args[0] is hostname
        case block.arity
        when 2
          if DRbQS::Setting::SSH === setting
            ssh_setting = setting
          else
            ssh_setting = DRbQS::Setting::SSH.new
            ssh_setting.value.argument << type.to_s
            ssh_setting.mode_setting = setting
          end
          yield(ssh_setting.mode_setting.value, ssh_setting.value)
          unless ssh_setting.value.argument[0] == type
            ssh_setting.value.argument.unshift(type)
          end
          ary[1][:ssh] = true
          ary[1][:setting] = ssh_setting

          if type == "server" && !template && !args[0]
            raise ArgumentError, "No hostname of SSH server"
          end
        when 1
          if DRbQS::Setting::SSH === setting
            raise ArgumentError, "Inherited definition is over ssh."
          end
          yield(setting.value)
          ary[1][:ssh] = false
          ary[1][:setting] = setting
          ary[1][:unix_domain_socket] = (!template && !args[0])
        else
          raise ArgumentError, "Block must take one or two arguments."
        end
        ary
      end
      private :__register__

      def __register_server__(template, name, load_def, *args, &block)
        if load_def
          if DRbQS::Setting::Base === load_def
            setting = load_def
          elsif data = @__server__.assoc(load_def.intern)
            setting = data[1][:setting].clone
          else
            raise ArgumentError, "Not registered definition '#{load_def}'."
          end
        else
          setting = DRbQS::Setting::Server.new
        end
        @__server__ << __register__(:server, setting, name, template, args, &block)
      end
      private :__register_server__

      def __register_node__(template, name, load_def, *args, &block)
        if load_def
          if DRbQS::Setting::Base === load_def
            setting = load_def
          elsif data = @__node__.assoc(load_def.intern)
            if data[1][:type] == :group
              raise ArgumentError, "Definition to inherit is group."
            end
            setting = data[1][:setting].clone
          else
            raise ArgumentError, "Not registered definition '#{load_def}'."
          end
        else
          setting = DRbQS::Setting::Node.new
        end
        @__node__ << __register__(:node, setting, name, template, args, &block)
      end
      private :__register_node__

      # To set properties of server we can use the similar options to the command 'drbqs-server'.
      # When we execute a server over ssh, we can use the similar options to the command 'drbqs-ssh'
      # Exceptionally, we can set files to load by 'load' method
      # and set a ssh server by 'connect' method.
      # If we omit the 'connect' method then the program tries to connect
      # the name specified as first argument.
      # 
      # @overload server(name, hostname, opts = {})
      #  @param [Symbol,String] name Server name
      #  @param [Symbol,String] hostname Hostname of server to access over SSH
      #  @param [Hash] opts The options of server
      #  @option opts [Boolean] :template Template for other servers to load, not actual server
      #  @option opts [Symbol] :load Inherit definition of other server
      # 
      # @overload server(name, opts = {})
      #  If hostname is omitted, the server uses UNIX domain socket and executes some nodes together.
      #  @param [Symbol,String] name Server name
      #  @param [Hash] opts The options of server
      #  @option opts [Boolean] :template Template for other servers to load, not actual server
      #  @option opts [Symbol] :load Inherit definition of other server
      # 
      # @example A server on localhost (Connections from nodes is over SSH)
      #  server :server_local, "example.com" do |srv|
      #    srv.load "server_definition.rb"
      #    srv.acl "/path/to/acl"
      #    srv.log_file "/path/to/log"
      #    srv.log_level Logger::ERROR
      #    srv.sftp_user "username"
      #    srv.sftp_host "example.com"
      #  end
      # 
      # @example A server executed over SSH
      #  server :server_ssh, "example.co.jp" do |srv, ssh|
      #    srv.load "server_definition.rb"
      #    srv.acl "/path/to/acl"
      #    srv.log_level Logger::ERROR
      #    srv.sftp_user "username"
      #    srv.sftp_host "example.com"
      #  
      #    ssh.connect "hostname"
      #    ssh.directory "/path/to/dir"
      #    ssh.shell "bash"
      #    ssh.rvm "ruby-head"
      #    ssh.rvm_init "/path/to/scripts/rvm"
      #    ssh.output "/path/to/output"
      #    ssh.nice 10
      #  end
      #
      # @example A server on localhost that uses UNIX domain socket (No node on other computer)
      #  server :server_unix_domain_socket do |srv|
      #    srv.load "server_definition.rb"
      #    srv.execute_node 4
      #  end
      def server(name, *args, &block)
        unless block_given?
          raise ArgumentError, "Block to define settings is not given."
        end
        name = name.intern
        if ind = @__server__.index { |n, data| name == n }
          old_data = @__server__.delete_at(ind)
        else
          old_data = nil
        end
        opts = args.extract_options!
        opts.assert_valid_keys(:template, :load)
        if args.size > 1
          raise ArgumentError, "Invalid number of arguments."
        end
        hostname = args[0]
        if old_data
          if opts[:load]
            raise ArgumentError, "Can not set both reconfiguring and loading."
          end
          load_def = old_data[1][:setting]
          hostname = old_data[1][:args][0] if !hostname
        else
          load_def = opts[:load]
        end
        __register_server__(opts[:template], name, load_def, hostname, &block)
      end

      # To set properties of nodes we can use the similar options to the command 'drbqs-node'.
      # When we execute a server over ssh, we can use the similar options to the command 'drbqs-ssh'
      # Exceptionally, we can set a ssh server by 'connect' method.
      # If we omit the 'connect' method then the program tries to connect
      # the name specified as first argument.
      # 
      # @param [Symbol,String] name Node name
      # @param [Hash] opts The options of node
      # @option opts [Boolean] :template Template for other nodes to load, not actual node
      # @option opts [Symbol] :load Inherit definition of other node
      # @option opts [Boolean] :group Define the group of node
      # 
      # @example Nodes on localhost
      #  node :node_local do |nd|
      #    nd.process 3
      #    nd.load "load_lib.rb"
      #    nd.log_prefix "/path/to/log"
      #    nd.log_level Logger::DEBUG
      #  end
      # 
      # @example Nodes over ssh
      #  node :node_ssh do |nd, ssh|
      #    nd.process 3
      #    nd.load "load_lib.rb"
      #    nd.log_level Logger::DEBUG
      #  
      #    ssh.connect "hostname"
      #    ssh.directory "/path/to/dir"
      #    ssh.shell "bash"
      #    ssh.rvm "ruby-head"
      #    ssh.rvm_init "/path/to/scripts/rvm"
      #    ssh.output "/path/to/output"
      #    ssh.nice 10
      #  end
      # 
      # @example Node group
      #  node :node_group, :group => [:node_local, :node_ssh]
      def node(name, opts = {}, &block)
        opts.assert_valid_keys(:template, :load, :group)
        name = name.intern
        load_def = opts[:load]
        if ind = @__node__.index { |n, data| name == n }
          old_data = @__node__.delete_at(ind)
          if (opts[:group] && old_data[1][:type] != :group) ||
              (!opts[:group] && old_data[1][:type] == :group)
            raise ArgumentError, "Change type of definition on reconfiguring."
          elsif (!opts[:group] && load_def)
            raise ArgumentError, "Can not set both reconfiguring and loading."
          end
          load_def = old_data[1][:setting]
        else
          old_data = nil
        end
        if opts[:group]
          unless Array === opts[:group]
            raise ":group must be an array of node names."
          end
          data = {
            :type => :group, :template => true, :ssh => nil, :setting => nil,
            :args => opts[:group].map(&:intern)
          }
          @__node__ << [name, data]
        elsif block_given?
          __register_node__(opts[:template], name, load_def, &block)
        else
          raise ArgumentError, "Block to define settings is not given."
        end
      end

      # @param [Array] args Symbols of servers
      # @example Clear server definitions
      #  clear_server :server1, :server2
      def clear_server(*args)
        args.each do |arg|
          @__server__.delete_if do |name, data|
            name == arg.intern
          end
        end
      end

      # @param [Array] args Symbols of nodes
      # @example Clear node definitions
      #  clear_node :node1, :node2
      def clear_node(*args)
        args.each do |arg|
          @__node__.delete_if do |name, data|
            name == arg.intern
          end
        end
      end

      # We can set default server, default port, and default directory to output log.
      # @param [Hash] val the pair of key and value
      # @option val [Fixnum] :port Port number of a server
      # @option val [Symbol] :server Server executed by default
      # @option val [Array] :node Nodes executed by default if server has no node
      # @option val [String] :log Path of log of a server and nods on localhost
      # @example Set default value
      #  default :port => 13456, :server => :server_local, :log => "/tmp/drbqs_execute_log"
      def default(val = {})
        val.assert_valid_keys(:port, :server, :node, :log)
        val.delete_if { |key, v| !v }
        if val[:server]
          val[:server] = val[:server].intern
        end
        if val[:port]
          val[:port] = val[:port].to_i
        end
        raise "Invalid default value for :node." if val.has_key?(:node) && !(Array === val[:node])
        raise "Invalid default value for :log." if val.has_key?(:log) && !(String === val[:log])
        @__default__.merge!(val)
      end

      # @example Clear default value
      #  default_clear :port, :server, :log
      def default_clear(*keys)
        keys.each do |key|
          @__default__.delete(key)
        end
      end

      # We can set some messages shown by drbqs-execute -h.
      # @param [Hash] opts
      # @option opts [String] :message Simple message strings
      # @option opts [String] :server Path of server definition to output as help of server
      # @example Set usage
      #  usage :message => 'Calculate some value', :server => 'server.rb'
      def usage(opts = {})
        opts.assert_valid_keys(:message, :server)
        @__usage__.merge!(opts)
      end

      def __load__(path)
        instance_eval(File.read(path), path)
      end
    end
  end
end
