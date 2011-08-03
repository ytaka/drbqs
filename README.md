# DRbQS

Task queuing system over network that is implemented by dRuby.
Tasks created by a server are distributed to nodes for calculation.

- [http://rubygems.org/gems/drbqs](http://rubygems.org/gems/drbqs)
- [https://github.com/ytaka/drbqs](https://github.com/ytaka/drbqs)

## Summary

DRbQS is written as server-client system;
a server creates tasks and puts them into Rinda::TupleSpace;
nodes for calculation take tasks from Rinda::TupleSpace, calculate them,
and return their results to the server.

DRbQS also provides some utilities to define tasks,
to execute a server and nodes (over ssh),
to transfer files between a server and nodes,
to create temporary files and directories,
and to test and profile programs of DRbQS.

DRbQS is tested on Ubuntu 11.04 and
we can install DRbQS easily on Linux.
Note that due to some requirements, DRbQS does not work probably on Windows.

## Requirements & Installation

We can install gem of DRbQS.

    gem install drbqs

DRbQS uses Fiber, so ruby requires version 1.9.
Also, some features of DRbQS does not work on Windows platform
due to uses of Kernel#fork.
Because SSH is used to execute processes over network,
it is desirable that ssh servers on all computers are installed.

DRbQS requires the following gems.

- [filename](http://rubygems.org/gems/filename)
- [net-sftp](http://rubygems.org/gems/net-sftp)
- [net-ssh](http://rubygems.org/gems/net-ssh)
- [net-ssh-shell](http://rubygems.org/gems/net-ssh-shell)
- [sys-proctable](http://rubygems.org/gems/sys-proctable)
- [user_config](http://rubygems.org/gems/user_config)

If we want to profile programs for DRbQS
then we need to install [ruby-prof](http://rubygems.org/gems/ruby-prof).

    gem install ruby-prof

DRbQS saves configuration files in ~/.drbqs.
To create the directory, we type in a terminal

    drbqs-manage initialize

## Explanation of DRbQS

### Server of DRbQS

A server works as below.

1. Initialization
2. Check message from user or nodes
3. Check connection of nodes
4. Process result data from nodes
5. Execute some methods (which is called 'hook')
   - Process string data sent from user
   - Add new tasks if queue of the server is empty
   - and so on
6. Repeat 2-5 until all tasks are finished
7. Send finalization signals to nodes
8. Wait nodes exiting
9. Exit

### Node of DRbQS

A node works as below.

1. Connect to a server, takes an initialization task from the serve,
   and execute it
2. Create two threads: connection of server and calculation of tasks
3. Thread of connection checks signals from a server by an interval time
   and get new task if there is no calculating task
4. Thread of calculation processes a task
5. Receiving a finalization signal, the node exits

## Commands of DRbQS

### drbqs-server

Execute a server from a file in which the creation of tasks is written.

### drbqs-node

Specifying a file that defines class of tasks,
execute nodes to connect the server.

### drbqs-manage

Send some signals to a server and get some information.

### drbqs-ssh

Run processes of a server and a node over ssh.

### drbqs-execute

Execute set of a server and nodes from a file written as DSL,
which can be over SSH.

## Simple example

### Files

- **server.rb** : Definition of server
- **task.rb** : Class of tasks
- **execute.rb** : DSL to start processes.

The above examples are in the directory example/simple.

### server.rb

    require_relative 'task.rb'
    
    DRbQS.define_server do |server, argv, opts|
      task = DRbQS::Task.new(Sum.new(10, 20, 2), :calc) do |srv, result|
        puts "Result is #{result}"
      end
      server.queue.add(task)
    end

### task.rb

    class Sum
      def initialize(a, b, c)
        @a = a
        @b = b
        @c = c
      end
    
      def calc
        @a + @b + @c
      end
    end

### execute.rb

    DIR = File.dirname(__FILE__)
    
    default port: 12345
    
    server :local, "localhost" do |srv|
      srv.load File.join(DIR, 'server.rb')
    end
    
    node :local do |nd|
      nd.load File.join(DIR, 'task.rb')
    end

### drbqs-server and drbqs-node

Basic way of execution is how to use the commands drbqs-server and drbqs-node.
We move the same directory of server.rb and task.rb in a terminal.
To execute a server, we type the command

    drbqs-server server.rb

To execute a node, we type the command in another terminal

    drbqs-node druby://:13500 -l task.rb

Then, the node connects to the server and calculate a task.
When the node send the result of the task,
the result of sum is displayed in the terminal of the server.

### drbqs-execute

To run a server and some nodes all together,
we uses the command drbqs-execute and a definition file.
In the same directory of execute.rb, we type the command

    drbqs-execute execute.rb

Then, a server and a node run and
their output is saved to files in the directory 'drbqs\_execute\_log'.

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
