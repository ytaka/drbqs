require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Setting::Node do
  subject do
    DRbQS::Setting::Node.new
  end

  context "when there are invalid arguments" do
    it "should raise error by a value of invalid argument size." do
      subject.set_argument('1', 2, 3, 4)
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
      subject.set(:load, '/path/to/load/file')
      subject.set(:connect, 'druby://example.com:12345')
      lambda do
        subject.parse!
      end.should_not raise_error
    end

    it "should not change string for shell." do
      subject.set(:load, '/path/to/load/file')
      subject.set(:connect, 'druby://example.com:12345')
      subject.parse!
      lambda do
        subject.parse!
      end.should_not change(subject, :string_for_shell)
    end
  end
end
