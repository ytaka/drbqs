require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Execution::ServerDefinition do
  context "when we call class methods" do
    subject do
      DRbQS.class_variable_get(:@@server_def)
    end

    it "should define server." do
      lambda do
        DRbQS.define_server do |server, argv, opts|
          server.add_hook(:finish) do |serv|
            serv.exit
          end
        end
      end.should change { subject.instance_variable_get(:@default_server_opts) }.from(nil).to({})
    end

    it "should set parser of options." do
      lambda do
        DRbQS.option_parser do |opt, hash|
          opt.on('--test') do |v|
            hash[:test] = true
          end
        end
      end.should change { subject.instance_variable_get(:@option_parse) }.from(nil)
    end

    it "should parse options." do
      lambda do
        DRbQS.parse_option(['--test'])
      end.should change { subject.instance_variable_get(:@argv) }.from(nil)
    end

    it "should start server." do
      DRbQS::Server.should_receive(:new)
      begin
        # After DRbQS::Server.new returns nil, raise error
        DRbQS.start_server(:uri => 'druby://localhost:13500')
      rescue
      end
    end

    it "should return empty help message" do
      DRbQS.clear_definition
      DRbQS.option_help_message.should be_nil
    end

    it "should return help message." do
      DRbQS.option_parser do |opt, hash|
        opt.on('--test') do |v|
          hash[:test] = true
        end
      end
      DRbQS.option_help_message.should be_an_instance_of String
    end
  end

end
