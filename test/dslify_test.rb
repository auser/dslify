require "#{File.dirname(__FILE__)}/test_helper"

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
        dsl_methods :bank, :snobs, :author, :gilligans_island
      end
      @q = Quickie.new
    end
    it "should be able to set methods on self" do
      assert_nothing_raised do
        @q.bank "bobs"
      end
    end
    it "should set and then retrieve the same value back" do
      @q.snobs "are mean"
      assert_equal @q.snobs, "are mean"
    end
    it "should set and retrieve values back with an = sign" do
      @q.author = ["Ari Lerner"]
      assert_equal @q.author, ["Ari Lerner"]
    end
    it "should set these values in the h Hash on the object" do
      assert_raise NoMethodError do
        @q.movies "can be fun"
      end
    end
    it "should set multiple keys with set_vars_from_options" do
      @q.dsl_methods :a, :b
      @q.set_vars_from_options({:a => "a", :b => "b"})
      assert_equal @q.a, "a"
      assert_equal @q.b, "b"
    end
    it "should set methods even when they are called with a block" do
      @q.author Quickie.new do
      end
      assert_equal @q.author.class, Quickie
    end
    it "should not blow up when called with a ? at the end of the method" do
      @q.set_vars_from_options({:pete => "and pete"})
      assert_nothing_raised do
        @q.pete?
      end
    end
    it "should return false if the method exists" do
      assert_equal @q.bobs?, false
    end
    it "should return true if the option is set" do
      @q.gilligans_island "is a tv show"
      assert @q.gilligans_island?
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
      assert_equal @bang.says, "vmrun"
      @bang = Bang.new do
        says "snake"
      end
      assert_equal @bang.says, "snake"
    end
  end
  
  
  context "with inheritance and classes" do
    before do
      class Pop
        include Dslify
        default_options :name => "pop"
        def initialize(o={})
          set_vars_from_options(o)
        end
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
      end
      
      class Defaults < Pop
        default_options(
          :global_default => "red_rum"
        )
      end
      
      @pop = Pop.new      
      @foo = Foo.new
      @bar = Bar.new
    end
    it "should take the default options set on the class" do
      assert_equal @pop.dsl_options[:name], "pop"
      assert_equal @pop.name, "pop"
    end
    it "should allow us to add defaults on the instance by calling dsl_options" do      
      # QuickieTest::Pop.name == "Cinnamon"
      @poptart = Pop.new :name => "Cinnamon"
      assert_equal @poptart.name, "Cinnamon"
    end
    it "should take the default options on a second class that inherits from the base" do
      assert_equal @foo.name, "fooey"
    end
    it "should take the default options on a third inheriting class" do
      assert_equal @bar.name, "pangy"
    end
    it "should not add a method not in the default_options" do
      assert_equal @bar.respond_to?(:boat), false      
    end
    it "should return the original default options test" do
      assert_equal @bar.dsl_options[:taste], "spicy"
      assert_equal @bar.dsl_options[:name], "pangy"
    end
    it "should set the default options of the child to the superclass's if it doesn't exist" do
      # QuickieTest::Dad => QuickieTest::Pop
      d = Dad.new
      assert_equal "pop", d.name
      d.name "Frankenstein"
      assert_equal d.name, "Frankenstein"
    end
    it "should raise if the method isn't found on itself, the parent or in the rest of the method missing chain" do
      assert_raise NoMethodError do
        Class.new.sanitorium
      end
    end
    it "should be able to reach the grandparent through the chain of dsify-ed classes" do
      # QuickieTest::Grandad => QuickieTest::Dad => QuickieTest::Pop
      assert Grandad.new.name, "pop"
    end
    it "should be able to add a class as a forwarder" do
      class Grandad
        forwards_to Defaults
      end
      g = Grandad.new
      # QuickieTest::Grandad => QuickieTest::Dad => QuickieTest::Defaults => QuickieTest::Dad => QuickieTest::Pop
      assert_equal g.global_default, "red_rum"
    end
    # it "should be able to take a method that responds to an object" do
    #   class Tanks
    #     include Dslify
    #     forwards_to :parent
    #     def initialize(obj)
    #       @parent = obj
    #     end
    #     def parent          
    #       @parent
    #     end
    #   end
    #   t = Tanks.new(@bar)
    #   # QuickieTest::Tanks => Object => #<QuickieTest::Bar>
    #   assert_equal t.taste, @bar.taste
    # end
  end
end