module DRbQS
  class Worker
    class Serialize
      class Unpacker
        def initialize
          @chunk = ''
          @next_size = nil
        end

        def feed(data)
          @chunk << data
        end

        HEADER_BYTE_SIZE = 4

        def next_object
          unless @next_size
            if @chunk.bytesize >= HEADER_BYTE_SIZE
              @chunk.force_encoding('BINARY')
              @next_size = @chunk[0, HEADER_BYTE_SIZE].unpack('N')[0]
              @chunk = @chunk[HEADER_BYTE_SIZE..-1]
            else
              return nil
            end
          end
          if @next_size && @chunk.bytesize >= @next_size
            data = @chunk[0, @next_size]
            @chunk = @chunk[@next_size..-1]
            @next_size = nil
            [:loaded, Marshal.load(data)]
          else
            nil
          end
        end
        private :next_object

        def each(&block)
          if block_given?
            while ary = next_object
              sym, obj = ary
              yield(obj)
            end
          else
            to_enum(:each)
          end
        end

        def feed_each(data, &block)
          feed(data)
          each(&block)
        end
      end

      def self.dump(obj)
        str = Marshal.dump(obj)
        [str.size].pack('N') << str
      end
    end
  end
end
