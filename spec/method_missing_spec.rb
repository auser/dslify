require File.dirname(__FILE__) + '/spec_helper'

class TestClass
  include MethodMissingSugar
end

describe "MethodMissingSugar" do
  before(:each) do
    @tc = TestClass.new
  end
  it "should add the value of the unknown variable into the options of the instance" do
    @tc.__options[:name].should be_nil
    @tc.name "is_my_name"
    @tc.__options[:name].should_not be_nil
  end
  it "should call the value in the options when calling it as a method" do
    @tc.__options[:valentine] = "will you be my"
    @tc.valentine.should == "will you be my"
  end
  it "should accept a method called on the instance without an = sign" do
    @tc.pop "goes the weasel"
    @tc.pop.should == "goes the weasel"
  end
  it "should accept a method with the = sign which should set the variable" do
    @tc.hop = "goes the bunny"
    @tc.hop.should == "goes the bunny"
  end
end