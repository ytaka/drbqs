require 'drbqs/execute/register'

module DRbQS
  class ProcessDefinition

    attr_reader :register

    # @param [Symbol] server Symbol of server name
    # @param [Array] node An array of Symbol which means node name
    # @param [String] port Port number
    # @param [IO,nil] io IO object to output
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
      data
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
      uri = nil
      if ary = get_server_setting(name)
        data = ary[1]
        if data[:unix_domain_socket]
          uri = DRbQS::Misc.uri_drbunix(data[:setting].value.unix.first)
        else
          uri = DRbQS::Misc.create_uri(:host => data[:args][0], :port => server_port)
        end
      end
      uri
    end
    private :server_uri

    PATH_CPUINFO = "/proc/cpuinfo"

    def get_suitable_process_num
      n = 0
      if File.exist?(PATH_CPUINFO)
        n = File.read(PATH_CPUINFO).lines.count { |l| /^processor/ =~ l }
      end
      if n <= 0
        n = 1
        puts_progress "Can not determine suitable process number, that is, can not count 'processor' lines in /proc/cpuinfo"
      end
      puts_progress "Execute #{n} processes to deal with tasks"
      n
    end
    private :get_suitable_process_num

    def execute_server(server_args)
      if ary = get_server_setting(@server)
        name = ary[0].to_s
        data = ary[1]
        puts_progress "Execute server '#{name}' (#{data[:ssh] ? 'ssh' : 'local'})"
        setting = data[:setting]
        hostname = data[:args][0]
        type = data[:type]
        if data[:ssh]
          setting.value.connect name unless setting.set?(:connect)
          server_setting = setting.mode_setting
        else
          server_setting = setting
          server_setting.value.daemon FileName.create(local_log_directory, "server_execute.log", :position => :middle)
        end
        server_setting.set_server_argument(*server_args)
        if data[:unix_domain_socket]
          unless server_setting.value.unix
            server_setting.value.unix DRbQS::Temporary.socket_path
          end
          unless server_setting.value.execute_node
            server_setting.value.execute_node get_suitable_process_num
          end
        else
          server_setting.value.port server_port
          unless server_setting.set?(:sftp_host)
            server_setting.value.sftp_host hostname
          end
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
      mes = "Invalid server definition: #{err.to_s} (#{err.class.to_s})"
      begin
        mes = "#{setting.string_for_shell}; " << mes if setting.respond_to?(:string_for_shell)
      rescue
      end
      new_err = err.class.new(mes)
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end

    def execute_one_node(name, data, uri)
      puts_progress "Execute node '#{name}' (#{data[:ssh] ? 'ssh' : 'local'})"
      setting = data[:setting]
      node_setting = (data[:ssh] ? setting.mode_setting : setting)
      node_setting.value.argument.clear
      node_setting.value.connect uri
      if data[:ssh]
        unless setting.set?(:connect)
          setting.value.connect name.to_s
        end
      else
        node_log_dir = FileName.create(local_log_directory, "node_#{name}_log", :directory => :self)
        setting.clear :log_stdout
        setting.value.log_prefix File.join(node_log_dir, 'node')
        setting.value.daemon File.join(node_log_dir, 'execute.log')
      end
      setting.parse!
      # TODO:
      # If node is on localhost then program is terminated here,
      # because the node is executed as daemon process.
      setting.exec
    rescue Exception => err
      puts_progress "Fail to execute node '#{name.to_s}'"
      mes = "Invalid node definition: #{err.to_s} (#{err.class.to_s})"
      begin
        mes = "#{setting.string_for_shell}; " << mes if setting.respond_to?(:string_for_shell)
      rescue
      end
      new_err = err.class.new(mes)
      new_err.set_backtrace(err.backtrace)
      raise new_err
    end
    private :execute_one_node

    def each_node_to_execute(&block)
      each_node(@node || @register.__default__[:node], &block)
    end
    private :each_node_to_execute

    TIME_INTERVAL_EXECUTE_NODE = 1

    def execute_node
      uri = server_uri(@server)
      if uri && /^drbunix/ !~ uri
        each_node_to_execute do |name, data|
          execute_one_node(name, data, uri)
          # If there is no time interval then drb does not work properly.
          sleep(TIME_INTERVAL_EXECUTE_NODE)
        end
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
      if ary = get_server_setting(@server)
        default_server = ary[0]
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
        if data[:unix_domain_socket]
          prop = "local(unix socket domain)"
        elsif data[:ssh]
          prop = "ssh"
        else
          prop = "local(ssh)"
        end
        str << (info[:default][:server] == name ? " * " : (data[:template] ? " - " : "   "))
        str << sprintf("%- #{string_name_size}s  %s\n", name, prop)
      end
      str << "\nNode:\n"
      info[:node].each do |name, data|
        if data[:type] == :group
          prop = 'group: ' << data[:args].map(&:to_s).join(',')
        else
          prop = (data[:ssh] ? 'ssh' : 'local')
        end
        if info[:default][:node].include?(name)
          str << " * "
        elsif data[:type] == :group
          str << " # "
        elsif data[:template]
          str << " - "
        else
          str << "   "
        end
        str << sprintf("%- #{string_name_size}s  %s\n", name, prop)
      end
      str << "\nDefault port:\n   #{info[:default][:port]}"
      str << "\n\nHelp:\n"
      str << "   ssh:   Process over SSH\n"
      str << "   local: Process on localhost\n"
      str << "   *: default, -: template, #: node group"
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

    def test_consistency
      # Test existence of default server
      if @server && !get_server_setting(@server)
        raise "Invalid default server: #{@server.inspect}"
      end
      # Test existences of default nodes
      if node_names = default_value(:node)
        all_node_find_p = true
        node_names.each do |node|
          unless get_node_data(node)
            all_node_find_p = false
            $stderr.puts "Node definition #{node.inspect} does not exist!"
          end
        end
        unless all_node_find_p
          raise "Invalid default node."
        end
      end
    end

    TIME_INTERVAL_WAIT_SERVER_FINISH = 3

    def wait_server_finish
      if uri = server_uri(@server)
        puts_progress "Wait finish of server #{uri}"
        manage = DRbQS::Manage.new(:uri => uri)
        while manage.server_respond?
          sleep(TIME_INTERVAL_EXECUTE_NODE)
        end
      else
        puts_progress "We tried to wait finish, however, we can not determine server uri"
      end
    end
  end
end
