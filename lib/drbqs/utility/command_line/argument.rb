module DRbQS
  class Command
    module Argument
      def split_arguments(argv, split = '--')
        if n = argv.index(split)
          [argv[0..(n - 1)], argv[(n + 1)..-1]]
        else
          [argv, []]
        end
      end
      module_function :split_arguments

      def check_argument_size(argv, *args)
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
      module_function :check_argument_size
    end
  end
end
