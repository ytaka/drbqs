require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::ServerDefinition do
  context "when we call class methods" do
    before(:all) do
      @server_definition = DRbQS.class_variable_get(:@@server_def)
    end

    it "should define server" do
      lambda do
        DRbQS.define_server do |server, argv, opts|
          server.add_hook(:finish) do |serv|
            serv.exit
          end
        end
      end.should change { @server_definition.instance_variable_get(:@default_server_opts) }.from(nil).to({})
    end

    it "should set parser of options" do
      lambda do
        DRbQS.option_parser do |opt, hash|
          opt.on('--test') do |v|
            hash[:test] = true
          end
        end
      end.should change { @server_definition.instance_variable_get(:@option_parse) }.from(nil)
    end

    it "should parse options" do
      lambda do
        DRbQS.parse_option(['--test'])
      end.should change { @server_definition.instance_variable_get(:@argv) }.from(nil)
    end

    it "should start server" do
      DRbQS::Server.should_receive(:new)
      begin
        # After DRbQS::Server.new returns nil, raise error
        DRbQS.start_server(:uri => 'druby://localhost:13500')
      rescue
      end
    end
  end

end
