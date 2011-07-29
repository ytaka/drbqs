module DRbQS
  class ProcessDefinition
    class Register
      attr_reader :__server__, :__node__, :__default__, :__usage__

      # @__server__ and @__node__ are arrays of hash.
      # Keys of the hash are :type, :template, :ssh, :setting, and :args.
      def initialize
        @__server__ = []
        @__node__ = []
        @__default__ = {}
        @__usage__ = nil
      end

      def __register__(type, setting, name, template, args, &block)
        ary = [name.intern, { :type => type.intern, :template => template, :args => args }]
        type = type.to_s
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
        when 1
          if DRbQS::Setting::SSH === setting
            raise ArgumentError, "Inherited definition is over ssh."
          end
          yield(setting.value)
          ary[1][:ssh] = false
          ary[1][:setting] = setting
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
      # We can set :template and :load as an option.
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
      def register_server(name, *args, &block)
        name = name.intern
        if ind = @__server__.index { |n, data| name == n }
          old_data = @__server__.delete_at(ind)
        else
          old_data = nil
        end
        unless block_given?
          raise ArgumentError, "Block to define settings is not given."
        end
        case args.size
        when 2
          hostname = args[0]
          opts = args[1]
          unless Hash === opts
            raise ArgumentError, "Options must be hash."
          end
        when 1
          if Hash === args[0]
            hostname = nil
            opts = args[0]
          else
            hostname = args[0]
            opts = {}
          end
        else
          unless old_data
            raise ArgumentError, "Invalid argument size."
          end
        end
        if old_data
          if opts[:load]
            raise ArgumentError, "Can not set both reconfiguring and loading."
          end
          load_def = old_data[1][:setting]
          hostname = old_data[1][:args][0] if !hostname
        else
          load_def = opts[:load]
        end
        if !opts[:template] && !hostname
          raise ArgumentError, "Definition of server '#{name}' needs hostname."
        end
        __register_server__(opts[:template], name, load_def, hostname, &block)
      end

      # To set properties of nodes we can use the similar options to the command 'drbqs-node'.
      # When we execute a server over ssh, we can use the similar options to the command 'drbqs-ssh'
      # Exceptionally, we can set a ssh server by 'connect' method.
      # If we omit the 'connect' method then the program tries to connect
      # the name specified as first argument.
      # We can set :template, :load, and :group as options.
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
      def register_node(name, opts = {}, &block)
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

      def clear_server(*args)
        args.each do |arg|
          @__server__.delete_if do |name, data|
            name == arg.intern
          end
        end
      end

      def clear_node(*args)
        args.each do |arg|
          @__node__.delete_if do |name, data|
            name == arg.intern
          end
        end
      end

      # We can set default server, default port, and default directory to output log.
      # * Example of usage
      #   default :port => 13456, :server => :server_local, :log => "/tmp/drbqs_execute_log"
      def default(val = {})
        val.delete_if { |key, v| !v }
        if val[:server]
          val[:server] = val[:server].intern
        end
        if val[:port]
          val[:port] = val[:port].to_i
        end
        @__default__.merge!(val)
      end

      def default_clear(*keys)
        keys.each do |key|
          @__default__.delete(key)
        end
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
