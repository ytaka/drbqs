require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::ServerDefinition do
  context "when we call class methods" do
    before(:all) do
      @server_definition = DRbQS.class_variable_get(:@@server_def)
    end

    it "should define server" do
      @server_definition.should_receive(:define_server)
      DRbQS.define_server do |server, argv, opts|
        server.set_finish_hook do |serv|
          serv.exit
        end
      end
    end

    it "should set parser of options" do
      @server_definition.should_receive(:option_parser)
      DRbQS.option_parser do |opt, hash|
        opt.on('--test') do |v|
          hash[:test] = true
        end
      end
    end

    it "should parse options" do
      @server_definition.should_receive(:parse_option)
      DRbQS.parse_option(['--test'])
    end

  end

end
