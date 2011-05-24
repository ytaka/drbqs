require 'yaml'
require 'drbqs/config'

module DRbQS
  module SSH
    class Host
      def initialize
        @dir = DRbQS::Config.get_host_file_directory
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
