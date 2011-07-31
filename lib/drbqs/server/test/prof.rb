require 'ruby-prof'

module DRbQS
  module Test
    class Prof
      PRINTER_TYPE = [:flat, :graph, :graphhtml, :calltree]

      # :flat
      # :graph
      # :graphhtml
      # :calltree
      def initialize(printer_type, output)
        @printer_type = printer_type
        unless PRINTER_TYPE.include?(@printer_type)
          raise "Invalid printer type: #{@printer_type.inspect}"
        end
        @output = output
      end

      def get_printer(result)
        case @printer_type
        when :flat
          RubyProf::FlatPrinter.new(result)
        when :graph
          RubyProf::GraphPrinter.new(result)
        when :graphhtml
          RubyProf::GraphHtmlPrinter.new(result)
        when :calltree
          RubyProf::CallTreePrinter.new(result)
        end
      end
      private :get_printer

      def start
        RubyProf.start
      end

      def finish
        printer = get_printer(RubyProf.stop)
        if IO === @output
          printer.print(@output)
        else
          Kernel.open(@output, 'w') do |f|
            printer.print(f)
          end
        end
      end
    end
  end
end
