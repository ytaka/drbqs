require_relative 'mandelbrot.rb'

RESULT_DIR = 'result_mandelbrot'

DRbQS.option_parser("Calculate Mandelbrot set.") do |prs, opts|
  prs.on('-s NUM', '--step NUM', Float, 'Set the step size.') do |v|
    opts[:step] = v
  end
  prs.on('-l NUM', '--limit NUM', Float, 'Set the limit to search.') do |v|
    opts[:limit] = v
  end
  prs.on('-i NUM', '--iterate NUM', Integer, 'Set the iterate number.') do |v|
    opts[:iterate] = v
  end
  prs.on('-t NUM', '--threshold NUM', Float, 'Set the threshold value.') do |v|
    opts[:threshold] = v
  end
end

DRbQS.define_server(file_directory: RESULT_DIR) do |server, argv, opts|
  step_size = opts[:step] || 0.1
  limit = opts[:limit] || 2.0
  iterate = opts[:iterate] || 1000
  threshold = opts[:threshold] || 5

  mandelbrot = Mandelbrot.new(iterate, threshold)
  calc = CalcMandelbrot.new(mandelbrot)

  ranges = [[-limit..0, -limit..0, step_size], [-limit..0, 0..limit, step_size],
            [0..limit, -limit..0, step_size], [0..limit, 0..limit, step_size]]
  ranges.each_with_index do |ranges, i|
    args_ary = ["%02d.txt" % i] + ranges
    note_str = "#{ranges[0].inspect} #{ranges[1].inspect}"
    task = DRbQS::Task.new(calc, :calc_save, args: args_ary, note: note_str) do |srv, result|
      DRbQS::Transfer.decompress(srv, result)
    end
    server.queue.add(task)
  end
  server.add_hook(:finish) do |srv|
    puts "Save results to #{RESULT_DIR}"
    result_path = File.join(RESULT_DIR, "result.txt")
    Dir.glob(File.join(RESULT_DIR, "*.txt")).sort.each do |path|
      open(result_path, 'a+') do |out|
        out.print File.read(path)
      end
      FileUtils.rm(path)
    end
  end
end
