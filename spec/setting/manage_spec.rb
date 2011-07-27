require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::Setting::Manage do
  subject do
    DRbQS::Setting::Manage.new
  end

  context "when there are invalid arguments" do
    it "should raise error by an invalid mode." do
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

    [['process', 'invalid_command'],
     ['send', 'invalid_type', 'uri', 'string']].each do |args|
      it "should raise error for #{args.inspect}." do
        subject.set_argument(*args)
        lambda do
          subject.parse!
        end.should raise_error
      end
    end
  end

  context "when parsing" do
    [['signal', 'uri', 'server-exit'],
     ['signal', 'uri', 'node-exit-after-task', '3'],
     ['signal', 'uri', 'node-wake', '4'],
     ['signal', 'uri', 'node-sleep', '5'],
     ['status', 'uri'],
     ['history', 'uri'],
     ['process', 'list'],
     ['process', 'clear'],
     ['send', 'string', 'uri', 'string'],
     ['send', 'file', 'uri', __FILE__],
     ['initialize']].each do |args|
      it "should not raise error for #{args.inspect}." do
        subject.set_argument(*args)
        lambda do
          subject.parse!
        end.should_not raise_error
      end

      it "should not change string for shell for #{args.inspect}." do
        subject.set_argument(*args)
        subject.parse!
        lambda do
          subject.parse!
        end.should_not change(subject, :string_for_shell)
      end
    end
  end
end
