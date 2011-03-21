require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DRbQS::FileName do
  it "should return unchanged filename" do
    filename = DRbQS::FileName.new("abc.txt")
    filename.create.should == File.expand_path(File.dirname('.') + '/abc.txt')
  end

  it "should return new filename with number" do
    filename = DRbQS::FileName.new(__FILE__)
    path = filename.create
    File.exist?(path).should_not be_true
    path.should match(/\.\d+$/)
  end

  it "should return new filename with time" do
    filename = DRbQS::FileName.new(__FILE__, :type => :time)
    path = filename.create
    File.exist?(path).should_not be_true
    path.should match(/\.[\d_]+$/)
  end

  it "should return same filename" do
    filename = DRbQS::FileName.new(__FILE__)
    path = filename.create(:add => :prohibit)
    path.should == File.expand_path(__FILE__)
  end

  it "should return filename with prefix" do
    filename = DRbQS::FileName.new(__FILE__, :position => :prefix)
    path = filename.create
    dir, name = File.split(path)
    name.should match(/^\d+_/)
  end

  it "should return filename with addition before extension" do
    filename = DRbQS::FileName.new(__FILE__, :position => :middle)
    path = filename.create
    dir, name = File.split(path)
    ext = File.extname(name)
    name.should match(Regexp.new("_\\d+\\#{ext}"))
  end

end
