require 'fileutils'

module DRbQS
  class FileName

    # The options are following:
    # * :start
    #     Fixnum
    #     If ID string type is number, the ID starts from the specified number.
    # 
    # * :digit
    #     Fixnum
    #     ID number converted to a string with specified digit.
    # 
    # * :delimiter
    #     String
    # 
    # * :type
    #     :number or :time
    #     If the value is :number, use a number for ID string.
    #     If the value is :time, use current time.
    # 
    # * :position
    #     :prefix, :suffix, or :middle
    #     Set the position of an ID string.
    def initialize(basepath, opts = {})
      @basepath = File.expand_path(basepath)
      @number = opts[:start] || 0
      @digit = opts[:digit] || 2
      @type = opts[:type] || :number
      @position = opts[:position] || :suffix
      @delimiter = opts[:delimiter] || (@position == :suffix ? '.' : '_')
    end

    def get_basepath(extension = nil)
      if extension
        extension = '.' + extension unless extension[0] == '.'
        oldext = File.extname(@basepath)
        if oldext.size > 0
          @basepath.sub(Regexp.new("\\#{oldext}$"), extension)
        else
          @basepath + extension
        end
      else
        @basepath
      end
    end
    private :get_basepath

    def get_addition(add, filename)
      if add != :prohibit && (add == :always || File.exist?(filename))
        case @type
        when :time
          t = Time.now
          return t.strftime("%Y%m%d_%H%M%S_") + sprintf("%06d", t.usec)
        when :number
          s = sprintf("%0#{@digit}d", @number)
          @number += 1
          return s
        else
          raise "Invalid type of addition."
        end
      end
      nil
    end
    private :get_addition

    def add_addition(filename, addition)
      case @position
      when :prefix
        dir, base = File.split(filename)
        dir + '/' + addition + @delimiter + base
      when :middle
        dir, base = File.split(filename)
        ext = File.extname(base)
        if ext.size > 0
          filename.sub(Regexp.new("\\#{ext}$"), @delimiter + addition + ext)
        else
          filename + @delimiter + addition
        end
      else # :suffix
        filename + @delimiter + addition
      end
    end
    private :add_addition

    # The options are following:
    # * :extension
    #     String of extension
    #     Use the extension if the value is specified.
    # 
    # * :add
    #     :always    Always add an ID string.
    #     :auto      If some file exists, add an ID string.
    #     :prohibit  Even if some file exists, add no ID string.
    # 
    # * :directory
    #     If the value is true and the parent directory does not exist,
    #     create the directory.
    def create(opts = {})
      base = get_basepath(opts[:extension])
      FileUtils.mkdir_p(File.dirname(base)) if opts[:directory]
      if addition = get_addition(opts[:add], base)
        path = add_addition(base, addition)
        while File.exist?(path)
          if addition = get_addition(opts[:add], base)
            path = add_addition(base, addition)
          else
            raise "Can not create new filename."
          end
        end
        path
      else
        base
      end
    end
  end
end
