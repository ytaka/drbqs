require 'drbqs/execute/register'

module DRbQS
  class ProcessDefinition
    class InvalidServerDefinition < StandardError
    end

    class InvalidNodeDefinition < StandardError
    end

    attr_reader :register

    def initialize(server, node, port, io = nil)
      @server = server
      @node = node
      @port = port
      @register = DRbQS::ProcessDefinition::Register.new
      @io = io
    end

    def puts_progress(str)
      @io.puts str if @io
    end
    private :puts_progress

    # Log directory for processes on localhost.
    # Processes over ssh does not use this directory.
    def local_log_directory
      @logal_log_directory ||= FileName.create(default_value(:log) || 'drbqs_execute_log')
    end

    def load(path)
      @register.__load__(path)
    end

    def get_server_setting(name = nil)
      if data = (name ? @register.__server__.assoc(name.intern) : @register.__server__[0])
        { :name => data[0], :type => data[1][:type], :setting => data[1][:setting], :hostname => data[1][:args][0] }
      elsif name
        get_server_setting(nil)
      else
        nil
      end
    end
    private :get_server_setting

    def each_node(names = nil, &block)
      if names
        names.each do |name|
          if data = @register.__node__.assoc(name)
            yield(name, data[1])
          end
        end
      else
        @register.__node__.each do |name, data|
          yield(name, data[1])
        end
      end
    end
    private :each_node

    def default_value(key)
      @register.__default__[key]
    end
    private :default_value

    def server_port
      @port || default_value(:port) || ROOT_DEFAULT_PORT
    end
    private :server_port

    def server_uri(name)
      data = get_server_setting(name)
      DRbQS::Misc.create_uri(:host => data[:hostname], :port => data[:port])
    end
    private :server_uri

    def execute_server(server_args)
      if data = get_server_setting(@server)
        puts_progress "Execute server '#{data[:name].to_s}' (#{data[:type]})"
        setting = data[:setting]
        hostname = data[:hostname]
        type = data[:type]
        server_setting = type == :ssh ? setting.mode_setting : setting
        server_setting.set_server_argument(*server_args)
        server_setting.value.port server_port
        unless server_setting.value.sftp_host
          server_setting.value.sftp_host hostname
        end
        unless type == :ssh
          server_setting.value.daemon FileName.create(local_log_directory, "server_execute.log", :position => :middle)
        end
        setting.parse!
        unless type == :ssh
          server_setting.value.argument.each do |path|
            unless File.exist?(path)
              raise "File '#{path}' does not exist."
            end
          end
        end
        setting.exec
      end
    rescue Exception => err
      puts_progress "Fail to execute server '#{data[:name].to_s}'"
      mes = "#{err.to_s} (#{err.class.to_s})"
      mes = "#{setting.string_for_shell}; " << mes if setting.respond_to?(:string_for_shell)
      new_err = InvalidNodeDefinition.new(mes)
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end

    def execute_one_node(name, data, uri)
      puts_progress "Execute node '#{name.to_s}' (#{data[:type]})"
      setting = data[:setting]
      node_setting = (data[:type] == :ssh ? setting.mode_setting : setting)
      node_setting.value.argument.clear
      node_setting.value.connect uri
      unless data[:type] == :ssh
        node_log_dir = FileName.create(local_log_directory, 'node_execute_log', :directory => :self)
        setting.clear :log_stdout
        setting.value.log_prefix File.join(node_log_dir, 'node')
        setting.value.daemon File.join(node_log_dir, 'execute.log')
      end
      setting.parse!
      setting.exec
    rescue Exception => err
      puts_progress "Fail to execute node '#{name.to_s}'"
      mes = "#{err.to_s} (#{err.class.to_s})"
      mes = "#{setting.string_for_shell}; " << mes if setting.respond_to?(:string_for_shell)
      new_err = InvalidNodeDefinition.new(mes)
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end
    private :execute_one_node

    def execute_node
      uri = server_uri(@server)
      each_node(@node) do |name, data|
        execute_one_node(name, data, uri)
      end
    end

    def information
      info = {}
      info[:server] = @register.__server__.map do |ary|
        ary[0]
      end
      info[:node] = @register.__node__.map do |ary|
        ary[0]
      end
      if data = get_server_setting(@server)
        default_server = data[:name]
      else
        default_server = nil
      end
      info[:default] = { :server => default_server, :node => @node || info[:node], :port => server_port }
      info
    end

    def usage
      data = @register.__usage__
      str = data[:message] ? "\nDescription:\n#{data[:message]}" : ""
      if (server_file = data[:server]) && File.exist?(server_file)
        Kernel.load(server_file)
        if server_help = DRbQS.option_help_message
          str << "\n\n" << server_help
        end
      end
      str
    end
  end
end
