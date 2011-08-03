# Getting started

## Outline

We use example/mandelbrot as an example for use of DRbQS.
To use DRbQS we needs two files: a file to define class for tasks
and a file to define a server.
In addition, it is convenient to create a file
to define processes of a server and nodes.

## Example

### Class to calculate tasks: mandelbrot.rb

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


### Server: server.rb

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
    
### Definition of processes (optional): execute.rb

    DIR = File.dirname(__FILE__)
    
    server :local_server, "localhost" do |srv|
      srv.load File.join(DIR, 'server.rb')
    end
    
    node :local_node do |nd|
      nd.load File.join(DIR, 'mandelbrot.rb')
      nd.process 2 # For dual core CPU
    end

## mandelbrot.rb

This file defines class Mandelbrot and CalcMandelbrot.
The class CalcMandelbrot and its method calc\_save are for DRbQS::Task.
In the method calc\_save we creates a temporary file by DRbQS::Temporary.file
and save results to the file.
Then, we rename the temporary file and add it to queue of transferring.
The method calc\_save returns basename of the file transferred to the server
and the returned value will become an argument of hook of the task on the server.

## Definition of server

### A file for drbqs-server

The command "drbqs-server" takes a ruby file that defines a DRbQS server
and gets settings of the server (port number, settings of sftp, and so on)
from options of command line.
In the definition file we load necessary files to process tasks,
set a parser of command line arguments for the server
by the method "DRbQS.option\_parser",
and defines the body of server by the method "DRbQS.define\_server".

### DRbQS.option_parser

DRbQS.option_parser takes a block that has two arguments.
The first argument is a OptionParser object and
the second argument is a hash
that is used to save data from options of command line.

### DRbQS.define_server

The block of DRbQS.define\_server takes three arguments.
An argument of DRbQS.define\_server is the same as DRbQS::Server.new and
the first block argument is an object of DRbQS::Server.
the second block argument is ARGV parsed by DRbQS.option_parser and
the third block argument is the second block argument of DRbQS.option\_parser.
Using these variables, we can get arguments from command line.

We set tasks on the block of DRbQS.define\_server.
We create tasks by DRbQS::Task.new and
add them to queue of the server as the following

    server.queue.add(task)

In the block of DRbQS::Task.new
we decompress files transferred from nodes.
Then, when server finishes, :finish hook concatenates the files of results.

### Execute a server

To execute the server of which port number is 12345,
we type the following on terminal.

    drbqs-server server.rb -p 12345

We can set options of the server.
First, we confirm the options of the server.

    drbqs-server server.rb -h

The help messages are displayed.

We set the options of the command drbqs-server, add '--',
and set the options of the server.

For example,

    drbqs-server server.rb --execute-node 2 -- --limit 3.0 --step 0.1

The option --execute-node is useful,
it executes also nodes connecting to the server just after the server runs.

## Execute nodes

If the server runs with port 12345, then the command

    drbqs-node -l mandelbrot.rb druby://:12345

connects to the server of druby://:12345 and calculate tasks obtained from the server.
If we want to execute two node processes then we use either -P or -process option.
The command

    drbqs-node -P 2 -l mandelbrot.rb druby://:12345

execute two node processes.

If the calculation finishes, we find the directory 'result_mandelbrot'
including 'result.txt'.

## Execution over SSH

For example, if we want to execute on example.com then we type

    drbqs-ssh server user@example.com -d /path/to/mandelbrot -- server.rb -- --limit 3.0 --step 0.1

and

    drbqs-ssh node user@example.com -d /path/to/mandelbrot -- -l mandelbrot.rb -P 2

## Execute a server and nodes all together

We can execute a server and nods simultaneously as daemon processes.
We type the following

    drbqs-execute execute.rb
