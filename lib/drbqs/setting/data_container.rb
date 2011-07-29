module DRbQS
  class Setting
    class Source
      class DataContainer < BasicObject
        attr_accessor :argument
        attr_reader :__data__

        def initialize(array_class)
          @argument = []
          @__data__ = {}
          @__array__ = array_class
        end

        def method_missing(name, *args)
          if args.size > 0
            s = name.to_s
            key = (/=$/ =~ s ? s[0...-1].intern : name.intern)
            @__data__[key] = (@__array__ === args[0] ? args[0] : args)
          else
            @__data__[name]
          end
        end

        def __delete__(name)
          @__data__.delete(name.intern)
        end
      end

      def self.clone_container(obj)
        cl = DRbQS::Setting::Source::DataContainer.new(Array)
        cl.argument = obj.argument.clone
        obj.__data__.each do |key, val|
          cl.__data__[key] = val.clone
        end
        cl
      end
    end
  end
end
