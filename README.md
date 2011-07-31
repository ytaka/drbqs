# drbqs

Task queuing system over network that is implemented by dRuby.

## Summary

To use DRbQS, first, we start a server of DRbQS.
Second, we execute nodes (on same host or other hosts)
loading libraries required by the server
and connect the nodes to the server.

The behavior of nodes requests tasks, gets tasks from a server, processes the tasks,
and sends results of the tasks to the server.
The nodes work repeatedly until they get exit signal from server.
The server prepares tasks and signals to check that nodes are alive.
If the server does not communicate with the nodes unexpectedly,
the server deletes the nodes from node list and
requeues their calculating tasks.
We can set hooks for tasks.
The hooks are executed for results of the tasks
after the server accepts them from nodes.

The tasks are made from objects, an instance method of them, and its arguments.
Because we use Marshal.dump and Marshal.load for communication of a server and nodes,
the objects and the arguments must be marshalized.
And also we tell the server and the nodes the definition of class of the objects and the arguments.

## Requirements

DRbQS uses Fiber, so ruby requires version 1.9.
And we use net-ssh and net-ssh-shell to execute servers and nodes over ssh.

## Usage

### Preparation

We prepare a class to send tasks over network,
which has data and a method to deal with tasks.

For example, we make sum.rb as the following.

    class Sum
      def initialize(start_num, end_num)
        @num = [start_num, end_num]
      end
    
      def exec
        (@num[0]..@num[1]).inject(0) { |sum, i| sum += i }
      end
    end

The Sum class calculates sum of numbers from start_num to end_num.
The task we want to calculate is summation of numbers.

### Start server

We make server.rb as the following.

    require_relative 'sum.rb'
    
    DRbQS.define_server(:finish_exit => true) do |server, argv, opts|
      10.step(100, 10) do |i|
        task = DRbQS::Task.new(Sum.new(i - 10, i), :exec)
        server.queue.add(task)
      end
    end

In terminal, we load server.rb and execute server of drbqs.

    drbqs-server server.rb -p 13500

### Hook of server

We can use two hooks of server: 'empty_queue' and 'finish'.

    DRbQS.define_server do |server, argv, opts|
      server.add_hook(:empty_queue) do |srv|
        srv.queue.add( ... )
      end
      
      server.add_hook(:finish) do |srv|
        srv.exit
      end
    end

'finish' hook usually exit server program, but
an option :finish_exit for DRbQS.define_server or DRbQS.new
is nearly same.

We can use 'empty_queue' hook for adding tasks
when task queue is empty.

### Task generator

Arguments of DRbQS::TaskGenerator.new define instance variables,
which is implemented by Fiber and is executed by server's requests.

    task_generator = DRbQS::TaskGenerator.new(:abc => 'ABC', :def => 123, :data => [1, 2, 3])

The above example defines the following instance variables.

    @abc = 'ABC'
    @def = 123
    @data = [1, 2, 3]

Then, DRbQS::TaskGenerator#set method defines generation of tasks.
The block of the method is evaluated in the context of task_generator.
We can use @abc, @def, and @data on the above example.

    task_generator.set do
      @data.each do |i|
        create_add_task(i, :to_s)
      end
    end

DRbQS::TaskGenerator#create_add_task set a task
and DRbQS::TaskGenerator#new_tasks actually creates the task.
The arguments of DRbQS::TaskGenerator#create_add_task is
the same as DRbQS::Task.new.

To use the generator in DRbQS::Server,
we set the generator by DRbQS::Server#add_task_generator.

### Start node and connect server

Because nodes need class Sum,
the nodes load sum.rb when they starts.
Then, we use '-l' option for command 'drbqs-node'.
That is, we type in terminal.

    drbqs-node druby://localhost:13500/ -l sum.rb

We execute two processes to use two CPU cores.

    drbqs-node 2 druby://localhost:13500/ -l sum.rb

Then, if it succeeds, the calculation starts.
If it finishes, the server and node end.

## Provided task

### DRbQS::Task

DRbQS::Task is the basic class to define tasks of DRbQS,
whose objects are consisted of a object having method to process a task
and hook for returned result.
Basically, we define objects of DRbQS::Task and
give the objects to a server.

### DRbQS::TaskSet

DRbQS::TaskSet is a child class of DRbQS::Task and consists of group a number of tasks.
Objects of the class are generated when we set the option :collect to DRbQS::TaskGenerator#set
and therefore we are unaware of the objects of DRbQS::TaskSet
in many cases.

### DRbQS::CommandTask

DRbQS::CommandTask is a class to create tasks to execute some command.

## Temporary file

We can use temporary directories and files on nodes.
In methods to calculate tasks,
DRbQS::Temporary.file returns a name of temporary file and
DRbQS::Temporary.directory returns a name of temporary directory.
These temporary files and directories are deleted
after the task is completed.

## File transfer

When a task is finished on a node,
we can transfer files from a server to a client.
To be more precise, we enqueue a file by DRbQS::Transfer.enqueue
in methods to calculate tasks and
files in the queue are automatically transferred.
Then, original files on nodes are deleted after transferring.

## Contributing to drbqs
 
- Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
- Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
- Fork the project
- Start a feature/bugfix branch
- Commit and push until you are happy with your contribution
- Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
- Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Takayuki YAMAGUCHI. See LICENSE.txt for
further details.
