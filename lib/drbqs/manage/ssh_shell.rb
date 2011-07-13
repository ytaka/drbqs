require 'net/ssh'
require 'net/ssh/shell'

module DRbQS

  class Manage
    # Requirements:
    #   bash
    #   nohup
    class SSHShell
      class GetInvalidExitStatus < StandardError
      end

      attr_reader :user, :host, :directory, :port

      DEFAULT_RVM_SCRIPT = '$HOME/.rvm/scripts/rvm'
      DEFAULT_OUTPUT_FILE = 'drbqs_nohup.log'

      # :shell     shell to use
      # :dir       base directory of ssh server
      # :rvm       version of ruby on rvm
      # :rvm_init  path of script to initialize rvm
      # :output    file to output of stdout and stderr
      def initialize(dest, opts = {})
        @user, @host, @port = split_destination(dest)
        if !(@host && @user)
          raise "Invalid destination of ssh server."
        end
        @shell = opts[:shell] || 'bash'
        @rvm = opts[:rvm]
        @rvm_init = opts[:rvm_init]
        if (@rvm || @rvm_init) && !(String === @rvm_init)
          @rvm_init = DEFAULT_RVM_SCRIPT
        end
        @nohup_output = opts[:output] || DEFAULT_OUTPUT_FILE
        @directory = opts[:dir]
        @out = $stdout
        @nice = opts[:nice]
        @nohup = opts[:nohup]
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
        @out.puts "#{@user}@#{@host}$ #{cmd}" if @out
        @out.print result
      end
      private :output_command

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
        if ary[0].exit_status != 0
          raise GetInvalidExitStatus, "Can not execute '#{cmd}' on #{@host} properly."
        end
        ary
      end
      private :shell_exec_check

      def execute_command(&block)
        Net::SSH.start(@host, @user, :port => @port) do |ssh|
          ssh.shell(@shell) do |sh|
            shell_exec_check(sh, "cd #{@directory}") if @directory
            shell_exec_check(sh, "source #{@rvm_init}") if @rvm_init
            shell_exec_check(sh, "rvm use #{@rvm}") if @rvm
            yield(sh)
            shell_exec(sh, "exit")
          end
        end
      end
      private :execute_command

      def get_environment
        execute_command do |sh|
          ['echo "directory: " `pwd`',
           'echo "files:"',
           'ls',
           'if which rvm > /dev/null; then rvm info; else ruby -v; fi'].each do |cmd|
            shell_exec(sh, cmd)
          end
        end
      end

      def start(*args)
        cmd = args.join(' ')
        if @nice
          if Integer === @nice
            cmd = "nice -n #{@nice.to_s} " + cmd
          else
            cmd = "nice " + cmd
          end
        end
        execute_command do |sh|
          if @nohup
            pr, path = shell_exec_check(sh, "filename-create new -p middle -D parent -t time #{@nohup_output}")
            cmd = "nohup #{cmd} > #{path.strip} 2>&1 &"
          end
          shell_exec(sh, cmd)
        end
      end
    end
  end
end
