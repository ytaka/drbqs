require 'yaml'

module DRbQS
  class Config
    class SSHHost
      def initialize(dir)
        @dir = dir
        @host_files = (Dir.glob("#{@dir}/*.yaml") + Dir.glob("#{@dir}/*.yml")).map { |s| File.basename(s) }
      end

      def get(name)
        if (name.size > 0) && (host = @host_files.find { |s| /^#{name}/ =~ s })
          return File.join(@dir, host)
        end
        return nil
      end
      private :get

      def get_options(name)
        if path = get(name)
          return [path, YAML.load_file(path)]
        end
        return [nil, {}]
      end
    end
  end
end
