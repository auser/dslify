require "rubygems"
require "#{::File.dirname(__FILE__)}/../lib/dslify"
require "matchy"
require "context"

class Quickie
  include Dslify
  def initialize(&block)
    instance_eval &block if block
  end
end

class QuickieTest < Test::Unit::TestCase
  context "setting" do
    before do
      Quickie.class_eval do
        dsl_methods :bank, :snobs, :author
      end
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
      @q.author = ["Ari Lerner"]
      @q.author.should == ["Ari Lerner"]
    end
    it "should set these values in the h Hash on the object" do
      lambda{@q.movies "can be fun"}.should raise_error
    end
    it "should set multiple keys with set_vars_from_options" do
      @q.dsl_methods :a, :b
      @q.set_vars_from_options({:a => "a", :b => "b"})
      @q.a.should == "a"
      @q.b.should == "b"
    end
    it "should set methods even when they are called with a block" do
      @q.bobs Quickie.new do
      end
      @q.bobs.class.should == Quickie
    end
    it "should set the methods on the inner block" do
      @q.bobs Quickie.new do
        dsl_option :franks
        franks "franke"
      end
      @q.bobs.franks.should == "franke"
    end
    it "should not blow up when called with a ? at the end of the method" do
      @q.set_vars_from_options({:pete => "and pete"})
      lambda{@q.pete?}.should_not raise_error
    end
    it "should return false if the method exists" do
      @q.bobs?.should == false
    end
    it "should return true if the option is set" do
      @q.bank "is a tv show"
      @q.bank?.should == true
    end
  end
  
  context "default options" do
    setup do
      class Bang
        include Dslify
        default_options(
          :says => 'vmrun'
        )
        def initialize(opts={}, &block)
          instance_eval &block if block
        end
      end
      @bang = Bang.new
    end

    should "overwrite the default dsl option in instance_eval" do
      @bang.says.should == "vmrun"
      @bang = Bang.new do
        says "snake"
      end
      @bang.says.should == "snake"
    end
  end
  
  
  context "with inheritance and classes" do
    before do
      class Pop
        include Dslify
        def initialize(h={})
          dsl_options h
          super
        end
        default_options :name => "pop"
      end
      
      class Foo < Pop
        default_options :name=>'fooey'
      end
      
      class Bar < Pop
        default_options :name=>'pangy', :taste => "spicy"
      end
      
      class Dad < Pop
      end
      
      class Grandad < Dad
        forward_my_whole_chain true
      end
      
      class Defaults < Pop
        default_options(
          :global_default => "red_rum"
        )
        
        def self.global_method
          "red_pop"
        end
      end
      
      @pop = Pop.new
      @poptart = Pop.new :name => "Cinnamon"
      @foo = Foo.new
      @bar = Bar.new
    end
    it "should take the default options set on the class" do
      @pop.dsl_options[:name].should == "pop"
    end
    it "should allow us to add defaults on the instance by calling dsl_options" do
      @poptart.name.should == "Cinnamon"
    end
    it "should take the default options on a second class that inherits from the base" do
      @foo.name.should == "fooey"
    end
    it "should take the default options on a third inheriting class" do
      @bar.name.should == "pangy"
    end
    it "should not add a method not in the default_options" do
      @bar.respond_to?(:boat).should == false      
    end
    it "should return the original default options test" do
      @bar.default_options[:taste].should == "spicy"
      @bar.default_options[:name].should == "pangy"
    end
    it "should set the default options of the child to the superclass's if it doesn't exist" do
      d = Dad.new
      d.name.should == "pop"
    end
    it "should raise if the method isn't found on itself, the parent or in the rest of the method missing chain" do
      lambda {
        Class.new.sanitorium
      }.should raise_error
    end
    it "should be able to reach the grandparent through the chain of dsify-ed classes" do
      Grandad.new.name.should == "pop"
    end
    it "should be able to add a class as a forwarder" do
      class Grandad
        forwards_to Defaults
      end
      g = Grandad.new
      g.global_default.should == "red_rum"
    end
    it "should be able to add a class as a forwarder and get a method" do
      g = Grandad.new
      g.global_method.should == "red_pop"
    end
  end
end