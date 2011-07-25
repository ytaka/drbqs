module DRbQS
  class Setting
    class SSH < DRbQS::Setting::Base
      include DRbQS::Command::Argument

      def initialize
        super(:all_keys_defined => true) do
          [:dir, :shell, :rvm, :rvm_init, :output].each do |key|
            register_key(key, :check => 1)
          end
          register_key(:nice, :check => 1, :default => [10])
          set_argument_condition(:>, 0)
        end
        @ssh_argument = DRbQS::Setting::Source.new(nil)
      end

      def set_ssh_argument(*args)
        @ssh_argument.set_argument(*args)
      end

      def command_line_argument(escape = nil)
        ary = super(escape)
        ssh_args = @ssh_argument.command_line_argument(escape)
        if ssh_args.size > 0
          ary << '--'
          ary.concat(ssh_args)
        end
        ary
      end

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        [:dir, :shell, :rvm, :rvm_init, :nice].each do |key|
          @options[key] = get_first(key)
        end
        @output = get_first(:output)
        @argv = get_argument
        @ssh_args = get_ssh_argument
      end

      def command_list(io)
        if io
          ssh_host = DRbQS::Config.new.ssh_host
          ioputs ssh_host.config_names.join("\n")
        end
      end
      private :command_list

      def only_first_argument
        check_argument_size(@argv, :==, 1)
        @argv[0]
      end
      private :only_first_argument

      def command_show(io)
        if io
          name = only_first_argument
          ssh_host = DRbQS::Config.new.ssh_host
          if path = ssh_host.get_path(name)
            io.puts File.read(path)
          else
            raise ArgumentError, "Can not find configuration file '#{name}'."
          end
        end
      end
      private :command_show

      def manage_ssh(dest, io)
        DRbQS::Manage::SSHExecute.new(dest, { :io => io }.merge(@options))
      end
      private :manage_ssh

      def command_environment(io)
        dest = only_first_argument
        manage_ssh(dest, io).get_environment
      end
      private :command_environment

      def command_execute(io)
        dest = only_first_argument
        mng_ssh = manage_ssh(dest, io)
        if @ssh_args.size > 0
          mng_ssh.command(@ssh_args)
        else
          raise "There is no command for ssh."
        end
      end
      private :command_execute

      def command_server(io)
        dest = only_first_argument
        manage_ssh(dest, io).server(@ssh_args, :nice => @nice, :daemon => @output)
      end
      private :command_server

      def command_node(io)
        dest = only_first_argument
        manage_ssh(dest, io).node(@ssh_args, :nice => @nice, :daemon => @output)
      end
      private :command_node

      def exec(io = nil)
        case @command
        when 'list'
          command_list(io)
        when 'show'
          command_show(io)
        when 'environment'
          command_environment(io)
        when 'execute'
          command_execute(io)
        when 'server'
          command_server(io)
        when 'node'
          command_node(io)
        else
          raise ArgumentError, "Invalid command '#{@command}'."
        end
      end
    end
  end
end
