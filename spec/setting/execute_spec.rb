require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Setting::Execute do
  subject do
    DRbQS::Setting::Execute.new
  end

  context "when there are invalid arguments" do
    it "should raise error by a value of invalid argument size." do
      subject.set_argument('first', 'second')
      lambda do
        subject.parse!
      end.should raise_error
    end

    it "should raise error by a value of invalid key." do
      subject.set(:invalid_key, 1, 2, 3)
      subject.set_argument('first')
      lambda do
        subject.parse!
      end.should raise_error
    end
  end

  context "when parsing" do
    it "should not raise error." do
      subject.set(:port, 123)
      subject.set(:server, 'server')
      subject.set(:node, 'node')
      subject.set(:no_server)
      subject.set(:no_node)
      subject.set_argument('one')
      lambda do
        subject.parse!
      end.should_not raise_error
    end

    it "should not change string for shell." do
      subject.set(:port, 123)
      subject.set(:server, 'server')
      subject.set(:node, 'node')
      subject.set(:no_server)
      subject.set(:no_node)
      subject.set_argument('one')
      subject.parse!
      lambda do
        subject.parse!
      end.should_not change(subject, :string_for_shell)
    end
  end
end
