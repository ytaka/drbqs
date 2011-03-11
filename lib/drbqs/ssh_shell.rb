require 'net/ssh'
require 'net/ssh/shell'

module DRbQS

  # Requirements:
  #   bash
  #   nohup
  class SSHShell
    attr_reader :user, :host, :directory

    DEFAULT_RVM_SCRIPT = '$HOME/.rvm/scripts/rvm'
    DEFAULT_OUTPUT_FILE = 'drbqs_nohup.log'

    # :shell     shell to use
    # :port      port number of ssh server
    # :rvm       version of ruby on rvm
    # :rvm_init  path of script to initialize rvm
    # :output    file to output of stdout and stderr
    def initialize(dest, opts = {})
      @user, @host, @directory = split_destination(dest)
      if !(@host && @user)
        raise "Invalid destination of ssh server."
      end
      @shell = opts[:shell] || 'bash'
      @rvm = opts[:rvm]
      @rvm_init = opts[:rvm_init]
      if (@rvm || @rvm_init) && !(String === @rvm_init)
        @rvm_init = DEFAULT_RVM_SCRIPT
      end
      @out = opts[:output] || DEFAULT_OUTPUT_FILE
      @port = opts[:port]
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
        directory = host_dir[(n + 1)..-1]
      else
        host = host_dir
        directory = nil
      end
      [user, host, directory].map { |s| s && s.size > 0 ? s : nil }
    end
    private :split_destination

    def execute_command(*cmds)
      Net::SSH.start(@host, @user, :port => @port) do |ssh|
        ssh.shell(@shell) do |sh|
          sh.execute "cd #{@directory}" if @directory
          sh.execute "source #{@rvm_init}" if @rvm_init
          sh.execute "rvm use #{@rvm}" if @rvm
          cmds.each do |c|
            sh.execute c
          end
          sh.execute "exit"
        end
      end
    end
    private :execute_command

    def get_environment
      execute_command('echo "directory: " `pwd`',
                      'echo "files:"',
                      'ls',
                      'if which rvm > /dev/null; then rvm info; else ruby -v; fi')
    end

    def start(*args)
      execute_command("nohup #{args.join(' ')} > #{@out} 2>&1 &")
    end
  end
end
