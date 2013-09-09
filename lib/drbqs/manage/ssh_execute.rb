require 'drbqs/manage/ssh_shell'

module DRbQS
  class Manage
    class SSHExecute
      COMMAND_NICE = "nice"
      COMMAND_DRBQS_SERVER = "drbqs-server"
      COMMAND_DRBQS_NODE = "drbqs-node"
      COMMAND_FILENAME_CREATE = "filename-create"

      # @param [String] dest Destination name
      # @param [Hash] opts Option hash
      # @option opts [boolean] :bundler  Use bundler to execute commands: filename-create, drbqs-server, and drbqs-node
      # @option opts [String] :shell     Same as options DRbQS::Manage::SSHShell
      # @option opts [String] :keys      Same as options DRbQS::Manage::SSHShell
      # @option opts [IO]     :io        Same as options DRbQS::Manage::SSHShell
      # @option opts [String] :directory Same as options DRbQS::Manage::SSHShell
      # @option opts [String] :rvm       Same as options DRbQS::Manage::SSHShell
      # @option opts [String] :rvm_init  Same as options DRbQS::Manage::SSHShell
      # @option opts [Hash]   :env       Same as options DRbQS::Manage::SSHShell
      def initialize(dest, opts = {})
        @ssh_host = DRbQS::Config.new.ssh_host
        opts = opts.dup
        path, options = @ssh_host.get_options(dest)
        dest = options.delete(:dest) || dest
        @bundler = opts.delete(:bundler)
        @ssh_shell = DRbQS::Manage::SSHShell.new(dest, options.merge(opts))
      end

      def command(command)
        @ssh_shell.execute_all(command)
      end

      def get_environment
        @ssh_shell.get_environment
      end

      # Add "bundle exec" if \@bundler is true
      def command_ruby(cmd)
        if @bundler
          cmd = "bundle exec #{cmd}"
        end
        cmd
      end
      private :command_ruby

      # Keys are :nice and :daemon.
      def add_command_options(cmd, daemon, nice)
        s = ''
        if nice
          s << "nice "
          s << "-n #{nice.to_s} " if Integer === nice
        end
        s << cmd << " --daemon " << daemon
      end
      private :add_command_options

      def create_new_directory(sh, dir)
        process, result = sh.exec("#{command_ruby(COMMAND_FILENAME_CREATE)} new -a always -D self -t time #{dir}", :check => true)
        result.strip!
      end
      private :create_new_directory

      # Add options --daemon and --log-file.
      def server(cmd_options, opts = {})
        ret = nil
        @ssh_shell.start do |sh|
          dir = create_new_directory(sh, opts[:daemon] || 'drbqs_server_log')
          cmd = add_command_options(command_ruby(COMMAND_DRBQS_SERVER), File.join(dir, 'daemon_server.log'), opts[:nice])
          cmd << " --log-file " << File.join(dir, 'server.log') << ' '
          cmd << cmd_options.join(' ')
          process, result = sh.exec(cmd)
          ret = (process.exit_status == 0)
        end
        ret
      end

      # Add options --daemon and --log-prefix.
      def node(cmd_options, opts = {})
        ret = nil
        @ssh_shell.start do |sh|
          dir = create_new_directory(sh, opts[:daemon] || 'drbqs_node_log')
          cmd = add_command_options(command_ruby(COMMAND_DRBQS_NODE), File.join(dir, 'daemon_node.log'), opts[:nice])
          cmd << ' --log-prefix ' << File.join(dir, 'node') << ' ' << cmd_options.join(' ')
          process, result = sh.exec(cmd)
          ret = (process.exit_status == 0)
        end
        ret
      end
    end
  end
end
