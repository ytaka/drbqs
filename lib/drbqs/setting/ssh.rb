module DRbQS
  class Setting
    class SSH < DRbQS::Setting::Base
      include DRbQS::Command::Argument

      attr_accessor :mode_setting

      def initialize
        super(:all_keys_defined => true) do
          [:directory, :shell, :rvm, :rvm_init, :output, :connect].each do |key|
            register_key(key, :check => 1)
          end
          register_key(:nice, :check => 1, :default => [10])
          set_argument_condition(:>=, 0)
        end
        @mode_setting = nil
      end

      def configure_mode_setting(type = nil, &block)
        if type ||= get_argument[0]
          unless @mode_setting
            case type.intern
            when :server
              @mode_setting = DRbQS::Setting::Server.new
            when :node
              @mode_setting = DRbQS::Setting::Node.new
            else
              @mode_setting = DRbQS::Setting::Base.new
            end
          end
          yield(@mode_setting.value)
        else
          raise DRbQS::Setting::InvalidArgument, "Command mode is not determined."
        end
      end

      def only_parsing
        if @mode_setting
          mode_setting_old = @mode_setting.clone
          super
          @mode_setting = mode_setting_old
        else
          super
        end
      end
      private :only_parsing

      def command_line_argument(escape = nil)
        ary = super(escape)
        ssh_args = @mode_setting.command_line_argument(escape)
        if ssh_args.size > 0
          ary << '--'
          ary.concat(ssh_args)
        end
        ary
      end

      def preprocess!
        if connect = get_first(:connect)
          value.argument << connect
          clear(:connect)
        end
        if type = get_argument[0]
          case type.intern
          when :server
            @mode_setting.clear(:log_file)
            @mode_setting.clear(:daemon)
          when :node
            @mode_setting.clear(:log_prefix)
            @mode_setting.clear(:daemon)
          end
        end
      end
      private :preprocess!

      # If there are invalid arguments,
      # this method raises an error.
      def parse!
        super
        [:directory, :shell, :rvm, :rvm_init, :nice].each do |key|
          if val = get_first(key)
            @options[key] = val
          end
        end
        @output = get_first(:output)
        @argv = get_argument
        @command = @argv.shift
        @mode_setting.parse!
        @mode_argument_array = @mode_setting.command_line_argument
      end

      def command_list(io)
        if io
          ssh_host = DRbQS::Config.new.ssh_host
          io.puts ssh_host.config_names.join("\n")
        end
      end
      private :command_list

      def only_first_argument
        check_argument_size(@argv, :==, 1)
        @argv[0]
      end
      private :only_first_argument

      def connecting_ssh_server
        only_first_argument
      end
      private :connecting_ssh_server

      def command_show(io)
        if io
          name = only_first_argument
          ssh_host = DRbQS::Config.new.ssh_host
          if path = ssh_host.get_path(name)
            io.puts File.read(path)
          else
            raise DRbQS::Setting::InvalidArgument, "Can not find configuration file '#{name}'."
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
        mng_ssh = manage_ssh(connecting_ssh_server, io)
        if @mode_argument_array.size > 0
          mng_ssh.command(@mode_argument_array)
        else
          raise "There is no command for ssh."
        end
      end
      private :command_execute

      def command_server(io)
        manage_ssh(connecting_ssh_server, io).server(@mode_argument_array, :nice => @nice, :daemon => @output)
      end
      private :command_server

      def command_node(io)
        manage_ssh(connecting_ssh_server, io).node(@mode_argument_array, :nice => @nice, :daemon => @output)
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
          raise DRbQS::Setting::InvalidArgument, "Invalid command '#{@command}'."
        end
      end
    end
  end
end
