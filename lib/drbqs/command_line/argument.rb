module DRbQS
  module CommandLineArgument
    def self.split_arguments(argv, split = '--')
      if n = argv.index(split)
        [argv[0..(n - 1)], argv[(n + 1)..-1]]
      else
        [argv, []]
      end
    end

    def self.check_argument_size(argv, *args)
      n = argv.size
      args.each_slice(2).each do |ary|
        if ary.size == 2
          unless n.__send__(*ary)
            raise "Invalid arguments number. Please refer to documents."
          end
        else
          raise ArgumentError, "Invalid argument to check array size."
        end
      end
      true
    end
  end
end
