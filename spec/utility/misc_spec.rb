require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'drbqs/utility/temporary'

describe DRbQS::Misc::LoggerDummy do
  subject do
    DRbQS::Misc::LoggerDummy.new
  end

  it "should respond to info." do
    subject.should respond_to(:info)
  end

  it "should respond to warn." do
    subject.should respond_to(:warn)
  end

  it "should respond to error." do
    subject.should respond_to(:error)
  end

  it "should respond to debug." do
    subject.should respond_to(:debug)
  end
end

describe DRbQS::Misc do
  context "when creating new uri" do
    it "should return uri of druby." do
      DRbQS::Misc.create_uri(:port => 10000).should == "druby://:10000"
    end

    it "should return uri of drbunix." do
      tmp_path = DRbQS::Temporary.file
      DRbQS::Misc.create_uri(:unix => tmp_path).should == "drbunix:#{tmp_path}"
    end

    it "should raise error for non-existing parent directory." do
      tmp_dir = DRbQS::Temporary.file
      tmp_path = File.join(tmp_dir, 'tmp_file')
      lambda do
        DRbQS::Misc.create_uri(:unix => tmp_path)
      end.should raise_error
    end

    it "should raise error for existing path." do
      tmp_path = DRbQS::Temporary.file
      open(tmp_path, 'w') do |f|
        f.puts 'hello world'
      end
      lambda do
        DRbQS::Misc.create_uri(:unix => tmp_path)
      end.should raise_error
    end

    after(:all) do
      DRbQS::Temporary.delete
    end
  end

  it "should create logger." do
    logger = DRbQS::Misc.create_logger(File.join(HOME_FOR_SPEC, 'tmp.log'), Logger::INFO)
    logger.should be_an_instance_of(Logger)
  end

  it "should return time string for history." do
    DRbQS::Misc.time_to_history_string(Time.now).should be_an_instance_of String
  end

  it "should return ramdom key" do
    a = DRbQS::Misc.random_key
    b = DRbQS::Misc.random_key
    a.should be_an_instance_of String
    b.should be_an_instance_of String
    a.should_not == b
  end
end
