# Format of File for drbqs-execute

## Outline

drbqs-execute evaluates files in the context of an object of
{DRbQS::ProcessDefinition::Register}.
Therefore, we can use methods of {DRbQS::ProcessDefinition::Register}
in files given to drbqs-execute.

drbqs-execute execute a server of which uri is made from hostname and port.
Moreover, drbqs-execute make nodes connecting to the uri of server.
The server and nodes can be over SSH.

## Example

### execute.rb

    #!/usr/bin/env drbqs-execute
    # -*-ruby-*-
    
    usage message: "Message of this file", server: File.join(File.dirname(__FILE__), 'server.rb')
    
    default server: :server1, port: 12345, node: [:node1, :node3, :node5], log: "/tmp/drbqs/log"
    
    ssh_directory = "/ssh/path/to"
    
    server :server1, 'example.com' do |server, ssh|
      ssh.directory ssh_directory
      ssh.output "/path/to/log"
      ssh.nice 5
      server.load "server.rb"
      server.log_level 'error'
    end
    
    server :local, 'localhost' do |server|
      server.load "server.rb"
      server.log_level 'error'
    end
    
    node :node_base, template: true do |node, ssh|
      ssh.directory ssh_directory
      ssh.output "/path/to/node_ssh"
      ssh.nice 10
      node.process 2
      node.load "server.rb"
      node.log_level 'error'
    end
    
    ssh_user = 'user_name'
    [1, 2, 3, 4, 5, 6].each do |n|
      name = "node%02d" % n
      node name, load: :node_base do |node, ssh|
        ssh.connect "#{ssh_user}@#{name}.example.com"
      end
    end
    
    node :even, group: [:node02, :node04, :node06]
    node :odd, group: [:node01, :node03, :node05]

### Execution

In the above example, there is the shebang line

    #!/usr/bin/env drbqs-execute

and therefore we can execute by

    ./execute.rb

If there is no shebang line, we type

    drbqs-execute execute.rb

### Help message

If we run the following command

    drbqs-execute -h execute.rb

then help message of server.rb is displayed in addition to that of drbqs-execute.

### Information of server and nodes

The command

    drbqs-execute -i

shows information of server and nodes.
The output is

    Server:
     * server1    ssh
       local      local
    Node:
     - node_base  ssh,template
       node01     ssh
       node02     ssh
       node03     ssh
       node04     ssh
       node05     ssh
       node06     ssh
     - even       group: node02,node04,node06
     - odd        group: node01,node03,node05
    Port: 12345

The character "*"  means default and "-" means virtual nodes (template or group).

## Methods

The following methods are available.

### server

"server" method corresponds to commands "drbqs-server" and "drbqs-ssh server".
This method takes two arguments (server name and hostname),
options set by hash and a block.
If the block takes only one argument then the server is on localhost.
If there are two block arguments then the server is executed over SSH.
The first argument of block has methods similar to
the options of command "drbqs-server".
The second argument has methods similar to the options of command "drbqs-ssh".
We can set the settings of servers by these methods.

See {DRbQS::ProcessDefinition::Register#server}

### node

"node" method corresponds to commands "drbqs-node" and "drbqs-ssh node",
which takes node name and options set by hash as arguments.
As the same way of method "server" we can define nodes by method "node"
The block taking one argument defines a node on localhost and
the block taking two arguments defines a node over SSH.
The first argument has methods similar to the options of command "drbqs-node" and
the second argument has methods similar to the options of command "drbqs-ssh".

See {DRbQS::ProcessDefinition::Register#node}

### clear\_server

See {DRbQS::ProcessDefinition::Register#clear\_server}

### clear\_node

See {DRbQS::ProcessDefinition::Register#clear\_node}

### default

We can set default server, default nodes, default port number of server
by method "default".

See {DRbQS::ProcessDefinition::Register#default}

### default_clear

See {DRbQS::ProcessDefinition::Register#default\_clear}

### usage

We can set help messages for "drbqs-execute --help <some_file>".

See {DRbQS::ProcessDefinition::Register#usage}
