module DRbQS
  class Config
    class SSHHost
      def initialize(dir)
        @dir = File.expand_path(dir)
      end

      def config_files
        (Dir.glob("#{@dir}/*.yaml") + Dir.glob("#{@dir}/*.yml")).sort
      end
      private :config_files

      def config_names
        config_files.map do |s|
          File.basename(s).sub(/\.ya?ml$/, '')
        end
      end

      def find_file(name)
        config_files.find do |s|
          File.basename(s).sub(/\.ya?ml$/, '') == name
        end
      end
      private :find_file

      def get_path(name)
        name = name.to_s
        name.size > 0 && find_file(name)
      end

      # +name+ is file name without extension.
      def get_options(name)
        if path = get_path(name)
          return [path, YAML.load_file(path)]
        end
        [nil, {}]
      end

    end
  end
end
