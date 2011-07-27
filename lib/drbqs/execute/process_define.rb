require 'drbqs/execute/register'

module DRbQS
  class ProcessDefinition
    class InvalidServerDefinition < StandardError
    end

    class InvalidNodeDefinition < StandardError
    end

    attr_reader :register

    def initialize(server, node, port)
      @server = server
      @node = node
      @port = port
      @register = DRbQS::ProcessDefinition::Register.new
    end

    def local_log_directory
      @logal_log_directory ||= FileName.create(default_value(:log) || 'drbqs_execute_log')
    end

    def load(path)
      @register.__load__(path)
    end

    def get_server_setting(name = nil)
      if data = (name ? @register.__server__.assoc(name.intern) : @register.__server__[0])
        [data[0], data[1][:type], data[1][:setting], data[1][:args][0]]
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
      name, type, setting, hostname = get_server_setting(name)
      DRbQS::Misc.create_uri(:host => hostname, :port => server_port)
    end
    private :server_uri

    def execute_server
      name, type, setting, hostname = get_server_setting(@server)
      server_setting = type == :ssh ? setting.mode_setting : setting
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
    rescue Exception => err
      new_err = InvalidServerDefinition.new("#{err.class.to_s} => #{err.to_s}")
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end

    def execute_one_node(data, target_server)
      uri = server_uri(target_server)

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
    end
    private :execute_one_node

    def execute_node
      each_node(@node) do |name, data|
        execute_one_node(data, @server)
      end
    rescue Exception => err
      new_err = InvalidNodeDefinition.new("#{err.class.to_s} => #{err.to_s}")
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end

    def information
      info = {}
      info[:server] = @register.__server__.map do |ary|
        ary[0]
      end
      info[:node] = @register.__node__.map do |ary|
        ary[0]
      end
      if ary = get_server_setting(@server)
        default_server = ary[0]
      else
        default_server = nil
      end
      info[:default] = { :server => default_server, :node => @node || info[:node], :port => server_port }
      info
    end
  end
end
