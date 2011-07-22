require 'drbqs/manage/ssh_shell'

module DRbQS
  class Manage
    class SSHExecute
      def initialize(dest, opts = {})
        @ssh_host = DRbQS::Config.new.ssh_host
        path, options = @ssh_host.get_options(dest)
        # $stdout.puts "Use configuration: #{path}" if path
        dest = options.delete(:dest) || dest
        @ssh_shell = DRbQS::Manage::SSHShell.new(dest, options.merge(opts))
      end

      def command(command)
        @ssh_shell.execute_all(command)
      end

      def get_environment
        @ssh_shell.get_environment
      end

      # Keys are :nice and :daemon.
      def add_command_options(cmd, daemon, nice)
        if nice
          s = "nice "
          s << "-n #{nice.to_s} " if Integer === nice
        else
          s = ''
        end
        s << cmd << " --daemon " << daemon
      end
      private :add_command_options

      def create_new_directory(sh, dir)
        process, result = sh.exec("filename-create new -a always -D self -t time #{dir}", :check => true)
        result.strip!
      end
      private :create_new_directory

      def server(cmd_options, opts = {})
        ret = nil
        @ssh_shell.start do |sh|
          dir = create_new_directory(sh, opts[:daemon] || 'drbqs_server_log')
          cmd = add_command_options('drbqs-server', File.join(dir, 'daemon_server.log'), opts[:nice])
          cmd << " --log-file " << File.join(dir, 'server.log') << ' '
          cmd << cmd_options.join(' ')
          process, result = sh.exec(cmd)
          ret = (process.exit_status == 0)
        end
        ret
      end

      def node(cmd_options, opts = {})
        ret = nil
        @ssh_shell.start do |sh|
          dir = create_new_directory(sh, opts[:daemon] || 'drbqs_node_log')
          cmd = add_command_options('drbqs-node', File.join(dir, 'daemon_node.log'), opts[:nice])
          cmd << ' ' << cmd_options.join(' ')
          process, result = sh.exec(cmd)
          ret = (process.exit_status == 0)
        end
        ret
      end
    end
  end
end
