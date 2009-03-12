require "rubygems"
require "matchy"
require "context"

# Quick 1-file dsl accessor
class Object  
  def h
    @h||={}
  end
  def set_vars_from_options(h={})
    h.each{|k,v|send k.to_sym, v } unless h.empty?
  end
  def method_missing(m,*a,&block)
    if block
      ((a[0].class==self.class)?a[0].instance_eval(&block): super)
    else
      ((a.empty?)?h[m]:h[m.to_s.gsub(/\=/,"").to_sym]=(a.size>1?a:a[0]))
    end
  end
end

class Quickie
end

class QuickieTest < Test::Unit::TestCase
  context "setting" do
    before do
      @q = Quickie.new
    end
    it "should be able to set methods on self" do
      lambda{@q.bank "bobs"}.should_not raise_error
    end
    it "should set and then retrieve the same value back" do
      @q.snobs "are mean"
      @q.snobs.should == "are mean"
    end
    it "should set and retrieve values back with an = sign" do
      @q.author = "Ari Lerner"
      @q.author.should == "Ari Lerner"
    end
    it "should set these values in the h Hash on the object" do
      @q.movies "can be fun"
      @q.h.keys.should == [:movies]
    end
    it "should set multiple keys with set_vars_from_options" do
      @q.set_vars_from_options({:a => "a", :b => "b"})
      @q.a.should == "a"
      @q.b.should == "b"
    end
  end
end