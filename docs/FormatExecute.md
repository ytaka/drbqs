# Format of File for drbqs-execute

## Explanation

drbqs-execute evaluates files in the context of an object of
{DRbQS::ProcessDefinition::Register}.
Therefore, we can use methods of {DRbQS::ProcessDefinition::Register}
in files given to drbqs-execute.

## Example: execute.rb

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

## Help message

If we run the following command

    drbqs-execute -h execute.rb

then help message of server.rb is displayed in addition to that of drbqs-execute.

## Methods

The following methods are available.

### server

"server" method corresponds to commands "drbqs-server" and "drbqs-ssh server".

See {DRbQS::ProcessDefinition::Register#server}

### node

"node" method corresponds to commands "drbqs-node" and "drbqs-ssh node".

See {DRbQS::ProcessDefinition::Register#node}

### clear\_server

See {DRbQS::ProcessDefinition::Register#clear\_server}

### clear\_node

See {DRbQS::ProcessDefinition::Register#clear\_node}

### default

See {DRbQS::ProcessDefinition::Register#default}

### default_clear

See {DRbQS::ProcessDefinition::Register#default\_clear}

### usage

See {DRbQS::ProcessDefinition::Register#usage}
