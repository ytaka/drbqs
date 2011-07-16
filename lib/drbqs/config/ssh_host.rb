module DRbQS
  class Config
    class SSHHost
      def initialize(dir)
        @dir = File.expand_path(dir)
      end

      def find_file(name)
        files = (Dir.glob("#{@dir}/*.yaml") + Dir.glob("#{@dir}/*.yml"))
        files.find { |s| File.basename(s).sub(/\.ya?ml/, '') == name }
      end
      private :find_file

      def get(name)
        name.size > 0 && find_file(name)
      end
      private :get

      # +name+ is file name without extension.
      def get_options(name)
        if path = get(name)
          return [path, YAML.load_file(path)]
        end
        [nil, {}]
      end
    end
  end
end
