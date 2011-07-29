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
      if !name
        data = nil
        @register.__server__.each do |server_data|
          unless server_data[1][:template]
            data = server_data
            break
          end
        end
        return nil unless data
      elsif !(data = @register.__server__.assoc(name.intern))
        return get_server_setting(nil)
      end
      { :name => data[0], :type => data[1][:type], :setting => data[1][:setting], :hostname => data[1][:args][0] }
    end
    private :get_server_setting

    def get_node_data(name)
      if ary = @register.__node__.assoc(name)
        ary[1]
      else
        nil
      end
    end
    private :get_node_data

    def each_node(names = nil, &block)
      if block_given?
        if names
          node_data = []
          i = 0
          while i < names.size
            name = names[i]
            if data = get_node_data(name)
              if data[:template]
                if :group == data[:type]
                  data[:args].each do |n|
                    names << n unless names.include?(n)
                  end
                end
              else
                node_data << [name, data]
              end
            end
            i += 1
          end
          node_data.each do |data|
            yield(*data)
          end
        else
          each_node(@register.__node__.map { |name, data| name }, &block)
        end
      else
        to_enum(:each_node, names)
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
      DRbQS::Misc.create_uri(:host => data[:hostname], :port => server_port)
    end
    private :server_uri

    def execute_server(server_args)
      if data = get_server_setting(@server)
        name = data[:name].to_s
        puts_progress "Execute server '#{name}' (#{data[:type]})"
        setting = data[:setting]
        hostname = data[:hostname]
        type = data[:type]
        if data[:ssh]
          setting.value.connect name
          server_setting = setting.mode_setting
        else
          server_setting = setting
          server_setting.value.daemon FileName.create(local_log_directory, "server_execute.log", :position => :middle)
        end
        server_setting.set_server_argument(*server_args)
        server_setting.value.port server_port
        unless server_setting.set?(:sftp_host)
          server_setting.value.sftp_host hostname
        end
        setting.parse!
        unless data[:ssh]
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
      new_err = InvalidServerDefinition.new(mes)
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end

    def execute_one_node(name, data, uri)
      puts_progress "Execute node '#{name}' (#{data[:type]})"
      setting = data[:setting]
      node_setting = (data[:ssh] ? setting.mode_setting : setting)
      node_setting.value.argument.clear
      node_setting.value.connect uri
      if data[:ssh]
        unless setting.set?(:connect)
          setting.value.connect name.to_s
        end
      else
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

    def each_node_to_execute(&block)
      each_node(@node || @register.__default__[:node], &block)
    end
    private :each_node_to_execute

    def execute_node
      uri = server_uri(@server)
      each_node_to_execute do |name, data|
        execute_one_node(name, data, uri)
      end
    end

    def information
      info = {}
      info[:server] = @register.__server__.map do |name, data|
        new_data = data.dup
        new_data.delete(:setting)
        [name, new_data]
      end
      info[:node] = @register.__node__.map do |name, data|
        new_data = data.dup
        new_data.delete(:setting)
        [name, new_data]
      end
      if data = get_server_setting(@server)
        default_server = data[:name]
      else
        default_server = nil
      end
      default_nodes = each_node_to_execute.map do |node_name, node_data|
        node_name
      end
      info[:default] = { :server => default_server, :node => default_nodes, :port => server_port }
      info
    end

    def information_string
      info = information
      str = "Server:\n"
      ary = (info[:server] + info[:node]).map do |name, data|
        name.size
      end
      string_name_size = ary.max
      info[:server].each do |name, data|
        prop = (data[:ssh] ? 'ssh' : 'local')
        prop << ',template' if data[:template]
        str << (data[:template] ? " - " : (info[:default][:server] == name ? " * " : "   "))
        str << sprintf("%- #{string_name_size}s  %s\n", name, prop)
      end
      str << "Node:\n"
      info[:node].each do |name, data|
        if data[:type] == :group
          prop = 'group: ' << data[:args].map(&:to_s).join(',')
        else
          prop = (data[:ssh] ? 'ssh' : 'local')
          if data[:template]
            prop << ',template'
          end
        end
        str << (data[:template] ? " - " : (info[:default][:node].include?(name) ? " * " : "   "))
        str << sprintf("%- #{string_name_size}s  %s\n", name, prop)
      end
      str << "Port: #{info[:default][:port]}"
    end

    def usage
      if data = @register.__usage__
        str = data[:message] ? "\nDescription:\n#{data[:message]}" : ""
        if (server_file = data[:server]) && File.exist?(server_file)
          Kernel.load(server_file)
          if server_help = DRbQS.option_help_message
            str << "\n\n" << server_help
          end
        end
        str
      else
        ''
      end
    end
  end
end
