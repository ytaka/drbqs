require 'net/ssh'
require 'net/ssh/shell'

module DRbQS

  class Manage
    # Requirements:
    #   bash
    class SSHShell
      class RubyEnvironment
        DEFAULT_RVM_SCRIPT = '$HOME/.rvm/scripts/rvm'

        attr_reader :directory, :rvm, :rvm_init, :env

        # :directory
        # :rvm
        # :rvm_init
        # :env
        def initialize(opts = {})
          @directory = opts[:directory]
          @rvm = opts[:rvm]
          @rvm_init = opts[:rvm_init]
          if (@rvm || @rvm_init) && !(String === @rvm_init)
            @rvm_init = DEFAULT_RVM_SCRIPT
          end
          @env = opts[:env]
        end

        def commands_to_set_env_on_bash
          if @env
            @env.map do |var, val|
              "export #{var}=#{val}"
            end
          else
            []
          end
        end
        private :commands_to_set_env_on_bash

        def setup_commands
          cmds = commands_to_set_env_on_bash
          cmds << "cd #{@directory}" if @directory
          cmds << "source #{@rvm_init}" if @rvm_init
          cmds << "rvm use #{@rvm}" if @rvm
          cmds
        end

        def get_environment_commands
          ['echo "directory: " `pwd`',
           'echo "files:"',
           'ls',
           'if which rvm > /dev/null; then rvm info; else ruby -v; fi']
        end
      end

      class InvalidDestination < StandardError
      end
      class GetInvalidExitStatus < StandardError
      end

      attr_reader :user, :host, :port, :keys

      # :shell     shell to use
      # :env       a hash of environmental variables and their values
      # :dir       base directory of ssh server
      # :rvm       version of ruby on rvm
      # :rvm_init  path of script to initialize rvm
      # :keys      path of a ssh key
      # :io        IO to output results of commands
      def initialize(dest, opts = {})
        @user, @host, @port = split_destination(dest)
        if !(@host && @user)
          raise InvalidDestination, "Invalid destination of ssh server."
        end
        @keys = opts.delete(:keys)
        @shell = opts[:shell] || 'bash'
        @ruby_environment = DRbQS::Manage::SSHShell::RubyEnvironment.new(opts)
        @out = opts[:io]
        @ssh = nil
      end

      def directory
        @ruby_environment.directory
      end

      def split_destination(dest)
        if (n = dest.index("@")) && n > 0
          user = dest[0..(n - 1)]
          host_dir = dest[(n + 1)..-1]
        else
          raise "Not include '@': #{dest}"
        end
        if n = host_dir.index(':')
          host = host_dir[0..(n - 1)]
          port = host_dir[(n + 1)..-1]
        else
          host = host_dir
          port = nil
        end
        [user && user.size > 0 ? user : nil,
         host && host.size > 0 ? host : nil,
         port && port.size > 0 ? port.to_i : nil]
      end
      private :split_destination

      def output_command(cmd, result)
        if @out
          @out.puts "#{@user}@#{@host}$ #{cmd}"
          @out.print result
        end
      end
      private :output_command

      # Return an array of a Net::SSH::Shell::Process object and a result string.
      def shell_exec_get_output(sh, cmd)
        result = ''
        pr_cmd = sh.execute!(cmd) do |sh_proc|
          sh_proc.on_output do |pr, data|
            result << data
          end
          sh_proc.on_error_output do |pr, data|
            result << data
          end
        end
        [pr_cmd, result]
      end
      private :shell_exec_get_output

      def shell_exec(sh, cmd)
        ary = shell_exec_get_output(sh, cmd)
        output_command(cmd, ary[1])
        ary
      end
      private :shell_exec

      def shell_exec_check(sh, cmd)
        ary = shell_exec(sh, cmd)
        n = ary[0].exit_status
        if n != 0
          raise GetInvalidExitStatus, "Can not execute properly on #{@host}.\nExit status: #{n}\ncommand: #{cmd}"
        end
        ary
      end
      private :shell_exec_check

      def exec(cmd, opts = {})
        unless @ssh
          raise "Not connect."
        end
        if opts[:check]
          shell_exec_check(@ssh, cmd)
        else
          shell_exec(@ssh, cmd)
        end
      end

      def start(&block)
        Net::SSH.start(@host, @user, :port => @port, :keys => @keys) do |ssh|
          ssh.shell(@shell) do |sh|
            @ruby_environment.setup_commands.each do |cmd|
              shell_exec_check(sh, cmd)
            end
            @ssh = sh
            yield(self)
            shell_exec(sh, "exit")
          end
        end
      ensure
        @ssh = nil
      end

      # :check
      def execute_all(commands, opts = {})
        results = []
        start do |ssh_shell|
          commands.each do |cmd|
            results << ssh_shell.exec(cmd, opts)
          end
        end
        results
      end

      def get_environment
        execute_all(@ruby_environment.get_environment_commands)
      end
    end
  end
end
