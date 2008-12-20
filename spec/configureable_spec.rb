require File.dirname(__FILE__) + '/spec_helper'

class TestClass2
  include Configurable
end

describe "configurable" do
  before(:each) do
    @tc = TestClass2.new
  end
  it "should set the name as frank" do
    @tc.configure({:name => "frank"})
    @tc.name.should == "frank"
  end
  it "should reset the name after it's been set" do
    @tc.configure({:name => "frank"})
    @tc.configure({:name => "timmy"})
    @tc.name.should == "timmy"
  end
  it "should be able to reconfigure itself" do
    @tc.configure(:name => "walter")
    @tc.reconfigure(:name => "dewey")
    @tc.name.should == "dewey"
  end
  it "should send an array if two arguments are given" do
    @tc.configure({:name => ["array", "ishere"]})
    @tc.name.should == ["array", "ishere"]
  end
end