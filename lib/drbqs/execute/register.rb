module DRbQS
  class ProcessDefinition
    class Register
      attr_reader :__server__, :__node__, :__default__, :__usage__

      def initialize
        @__server__ = []
        @__node__ = []
        @__default__ = {}
        @__usage__ = nil
      end

      def __register__(type, name, *args, &block)
        if block_given?
          type = type.intern
          case type
          when :server
            setting = DRbQS::Setting::Server.new
          when :node
            setting = DRbQS::Setting::Node.new
          else
            raise ArgumentError, "Invalid type of setting '#{type.to_s}'"
          end
          case block.arity
          when 2
            ssh_setting = DRbQS::Setting::SSH.new
            ssh_setting.value.argument << type.to_s
            yield(setting.value, ssh_setting.value)
            ssh_setting.mode_setting = setting
            unless ssh_setting.value.argument[0] == type.to_s
              ssh_setting.value.argument.unshift(type.to_s)
            end
            ary = [name.intern, { :type => :ssh, :setting => ssh_setting, :args => args }]
          when 1
            yield(setting.value)
            ary = [name.intern, { :type => type, :setting => setting, :args => args }]
          else
            raise ArgumentError, "Block must take one or two arguments."
          end
          instance_variable_get("@__#{type.to_s}__") << ary
        else
          raise ArgumentError, "Block to define settings is not given."
        end
      end
      private :__register__

      # To set properties of server we can use the similar options to the command 'drbqs-server'.
      # When we execute a server over ssh, we can use the similar options to the command 'drbqs-ssh'
      # Exceptionally, we can set files to load by 'load' method
      # and set a ssh server by 'connect' method.
      # 
      # * Example of a server on localhost
      # register_server(:server_local, "example.com") do |server|
      #   server.load "server_definition.rb"
      #   server.acl "/path/to/acl"
      #   server.log_file "/path/to/log"
      #   server.log_level Logger::ERROR
      #   server.sftp_user "username"
      #   server.sftp_host "example.com"
      # end
      # 
      # * Example of a server over ssh
      # register_server(:server_ssh, "example.co.jp") do |server, ssh|
      #   server.load "server_definition.rb"
      #   server.acl "/path/to/acl"
      #   server.log_level Logger::ERROR
      #   server.sftp_user "username"
      #   server.sftp_host "example.com"
      # 
      #   ssh.connect "hostname"
      #   ssh.directory "/path/to/dir"
      #   ssh.shell "bash"
      #   ssh.rvm "ruby-head"
      #   ssh.rvm_init "/path/to/scripts/rvm"
      #   ssh.output "/path/to/output"
      #   ssh.nice 10
      # end
      def register_server(name, hostname = nil, &block)
        __register__(:server, name, hostname || name.to_s, &block)
      end

      # To set properties of nodes we can use the similar options to the command 'drbqs-node'.
      # When we execute a server over ssh, we can use the similar options to the command 'drbqs-ssh'
      # Exceptionally, we can set a ssh server by 'connect' method.
      # 
      # * Example of nodes on localhost
      # register_node(:node_local) do |node|
      #   node.process 3
      #   node.load "load_lib.rb"
      #   node.log_prefix "/path/to/log"
      #   node.log_level Logger::DEBUG
      # end
      # 
      # * Example of nodes over ssh
      # register_node(:node_ssh) do |node, ssh|
      #   node.process 3
      #   node.load "load_lib.rb"
      #   node.log_level Logger::DEBUG
      # 
      #   ssh.connect "hostname"
      #   ssh.directory "/path/to/dir"
      #   ssh.shell "bash"
      #   ssh.rvm "ruby-head"
      #   ssh.rvm_init "/path/to/scripts/rvm"
      #   ssh.output "/path/to/output"
      #   ssh.nice 10
      # end
      def register_node(name, &block)
        __register__(:node, name, &block)
      end

      # We can set default server, default port, and default directory to output log.
      # * Example of usage
      #   default :port => 13456, :server => :server_local, :log => "/tmp/drbqs_execute_log"
      def default(val = {})
        val.delete_if { |key, v| !v }
        @__default__.merge!(val)
        if @__default__[:server]
          @__default__[:server] = @__default__[:server].intern
        end
        if @__default__[:port]
          @__default__[:port] = @__default__[:port].to_i
        end
      end

      def default_clear(key)
        @__default__.delete(key)
      end

      # We can set messages of usage and path of definition file of server
      # to output help of server on showing help.
      # * Example of usage
      # usage(:message => 'Calculate some value', :server => 'server.rb')
      def usage(opts = {})
        @__usage__ = opts
      end

      def __load__(path)
        instance_eval(File.read(path), path)
      end
    end
  end
end
