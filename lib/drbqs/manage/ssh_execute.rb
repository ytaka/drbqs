require 'drbqs/manage/ssh_shell'

module DRbQS
  class Manage
    class SSHExecute
      def initialize(dest, opts = {})
        @ssh_host = DRbQS::Config.new.ssh_host
        path, options = @ssh_host.get_options(dest)
        # $stdout.puts "Use configuration: #{path}" if path
        dest = options[:dest] || dest
        @ssh = DRbQS::Manage::SSHShell.new(dest, options.merge(opts))
      end

      def execute(command)
        @ssh.start(command)
      end

      def get_environment
        @ssh.get_environment
      end
    end
  end
end
