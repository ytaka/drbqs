require 'complex'

class Mandelbrot
  def initialize(iterate, threshold)
    @iterate = iterate
    @threshold = threshold
  end

  def map(z, c)
    z * z + c
  end

  def iterate_map(z, c, &block)
    z_old = z
    @iterate.times do |i|
      z_new = map(z_old, c)
      z_old = z_new
      yield(z_old) if block_given?
    end
    z_old
  end

  def diverge?(c)
    iterate_map(Complex(0.0, 0.0), c) do |z|
      if z.abs > @threshold
        return true
      end
    end
    false
  end
end

class CalcMandelbrot
  def initialize(mandelbrot)
    @mandelbrot = mandelbrot
  end

  def calc(io, xrange, yrange, step_size)
    xrange.step(step_size) do |x|
      yrange.step(step_size) do |y|
        c = Complex(x, y)
        unless @mandelbrot.diverge?(c)
          io.puts "#{c.real}\t#{c.imag}"
        end
      end
    end
  end

  def calc_save(basename, *args)
    file = DRbQS::Temporary.file
    open(file, 'w') do |f|
      calc(f, *args)
    end
    DRbQS::Transfer.enqueue(file, compress: true, rename: basename) # Return basename.
  end
end
