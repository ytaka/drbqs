module DRbQS
  class CommandManage < CommandBase
    def self.exec(argv)
      obj = self.new(argv)
      obj.exec
    end

    def initialize(argv)
      @mode = argv.shift
      @argv = argv
      @manage = DRbQS::Manage.new
    end

    def command_initialize
      DRbQS::CommandLineArgument.check_argument_size(@argv, :>=, 0, :<=, 1)
      @manage.set_home_directory(@argv[0])
      @manage.create_config
      exit_normally
    end
    private :command_initialize

    def command_process
      DRbQS::CommandLineArgument.check_argument_size(@argv, :>=, 0, :<=, 1)
      if @argv[0] == 'clear'
        @manage.clear_process
        exit_normally
      end
      list = @manage.list_process
      $stdout.puts "Server"
      list[:server].each do |uri, data|
        $stdout.puts "#{uri}"
        data.each do |k, v|
          $stdout.puts sprintf("  %-10s  %s", k, v)
        end
      end
      $stdout.puts "\nNode"
      list[:node].each do |pid, data|
        $stdout.puts "#{pid}"
        data.each do |k, v|
          $stdout.puts sprintf("  %-10s  %s", k, v)
        end
      end
      exit_normally
    end
    private :command_process

    def command_status
      DRbQS::CommandLineArgument.check_argument_size(@argv, :==, 1)
      @manage.set_uri(@argv[0])
      if status = @manage.get_status
        $stdout.puts status
      end
      exit_normally
    rescue DRb::DRbConnError => err
      $stderr.puts "Can not connect server: #{err.to_s}"
      exit_unusually
    end
    private :command_status

    def command_signal
      @manage.set_uri(@argv[0])
      signal = @argv[1]
      case signal
      when 'server-exit'
        DRbQS::CommandLineArgument.check_argument_size(@argv, :==, 2)
        @manage.send_exit_signal
        exit_normally
      when 'node-exit-after-task'
        DRbQS::CommandLineArgument.check_argument_size(@argv, :==, 3)
        node_id = @argv[2].to_i
        @manage.send_node_exit_after_task(node_id)
        exit_normally
      end
    end
    private :command_signal

    def exec
      case @mode
      when 'initialize'
        command_initialize
      when 'process'
        command_process
      when 'status'
        command_status
      when 'signal'
        command_signal
      end
      $stderr.puts "Invalid command: #{@mode}"
      exit_unusually
    end
  end
end
