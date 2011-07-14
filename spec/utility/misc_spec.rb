require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DRbQS::LoggerDummy do
  subject do
    DRbQS::LoggerDummy.new
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
