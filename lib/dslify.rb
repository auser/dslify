# Quick 1-file dsl accessor
=begin rdoc
  Dslify, born out of a need for improvement on Dslify
  
  Add dsl accessors to any class.
  
  Usage:
    class MyClass
      include Dslify
      
      dsl_methods :award, :people
    end
    
    mc = MyClass.new
    mc.award "Tony Award"
    mc.people ["Bob", "Frank", "Ben"]
    
  You can set defaults as well:
    class MyClass
      default_options :award => "Tony Award"
    end
  
  If your tree of available accessors runs higher and longer than
  just 1 file, for instance, if you use Parenting, you can set forwarders to 
  forward the query up the chain
  
  class MyClass
    forwards_to :parent
  end
=end
require "forwardable"

module Dslify
  module ClassMethods
    # Allow default options
    def default_options(hsh={})
      (@default_options ||= {}).merge!(hsh)
    end
    # For every method, add a default of nil to the default_options hash
    def dsl_methods(*arr)
      arr.each {|a| default_options({a => nil}) }
    end
    # Forwarders array. If the method cannot be found on self, then check the forwarders
    # to see if any of them respond to the method
    # Starts with self.class and self.class.superclass
    def forwarders
      @forwarders ||= [self, superclass]
    end
    # Add forwarders
    def forwards_to(*arr)
      arr.each {|a| forwarders << a }
    end
    def do_not_forward_my_whole_chain(t=false)
      @do_not_forward_my_whole_chain ||= t
    end
    # Can the class handle the method?
    def can_i_handle_the_method?(m)
      (respond_to?(m.to_sym) || default_options.has_key?(m.to_sym)) ? true : false
    end
    # Handle the method on self. Either send the method to self if it is
    # a method or fetch it from the dsl_options if it's in the dsl_options
    def handle_the_method(m, *a, &block)      
      m = m.to_sym unless m.is_a?(Symbol)
      if respond_to?(m)
        self.send(m.to_sym, *a, &block)
      elsif default_options.has_key?(m)
        self.send(m, *a, &block)
      else
        nil
      end
    end
  end
  
  module InstanceMethods
    def initialize(o={}, *a)
      add_chain_of_ancestry unless self.class.do_not_forward_my_whole_chain
      
      forwarders.each do |fwd|
        @dsl_options = (fwd.default_options).merge(dsl_options) if fwd.respond_to?(:default_options)
      end      
      dsl_options.each {|k,v| set(k,v)}
    end
    def default_options
      @default_options ||= self.class.default_options
    end
    def dsl_options(hsh={})
      (@dsl_options ||= default_options.merge(hsh)).merge!(hsh)
    end
    def dsl_methods(*arr)
      ((@dsl_methods ||= self.class.dsl_methods) << arr).flatten
    end
    def _forwarders
      @forwarders ||= self.class.forwarders
    end
    def forwarders
      _forwarders.map {|fwd| fwd.is_a?(Symbol) ? self.send(fwd) : fwd}
    end
    # Force set a dsl_option
    def dsl_option(k,v=nil)
      dsl_options[k.to_sym] = v
      add_method(k.to_sym)
    end
    alias :options :dsl_options
    
    # Set all the variables from the options
    def set_vars_from_options(h, contxt=self)
      h.each {|k,v| dsl_option(k,v)}
    end
    def add_chain_of_ancestry
      ancestry = self.class.ancestors[1..-1]        
      ancestry.each do |a|
        break if a.to_s =~ /Dslify/
        _forwarders << a
      end
    end
    def add_method(meth)
      instance_eval <<-EOM
        def #{meth}(n=nil)
          n ? (dsl_options[:#{meth}] = n) : dsl_options[:#{meth}]
        end
        def #{meth}=(n)
          dsl_options[:#{meth}] = n
        end
        def #{meth}?
          can_i_reach?(:#{meth})
        end
      EOM
    end

    # The power
    def method_missing(m,*a,&block)
      if block
        # If there are no arguments with the block, evaluate the block
        # in the local context
        if a.empty?
          (a[0].class == self.class) ? a[0].instance_eval(&block) : super
        else
          # If there are arguments, then we are operating on an argument that
          # takes a block, so let's store the instance and run the block on the instance
          inst = a[0]
          inst.instance_eval(&block)
          dsl_options[m] = inst
          add_method(m)
        end
      else        
        if a.empty?
          if m.to_s.include?("?")
            can_i_reach?(m)
          else
            fetch(m)
          end
        else
          clean_meth = m.to_s.gsub(/\=/,"").to_sym
          val = a.size > 1 ? a : a[0]
          set(clean_meth, val, &block)
        end
      end
    end
    
    # Can I handle the method passed to me? (method == variable)
    # If I respond to the method, then of course I'll handle the method
    # If the method is not in my method lookup table, then
    # check to see if the method is a dsl_method in the dsl_options. If either
    # are true, then I can handle the method, otherwise, I cannot
    def can_i_handle_the_method?(m)
      (respond_to?(m.to_sym) || dsl_options.has_key?(m.to_sym)) ? true : false
    end
    # Handle the method on self. Either send the method to self if it is
    # a method or fetch it from the dsl_options if it's in the dsl_options
    def handle_the_method(m, *a, &block)      
      m = m.to_sym unless m.is_a?(Symbol)
      if self.methods.include?(m)        
        self.send(m, *a, &block)
      else
        if dsl_options.has_key?(m)
          add_method(m.to_sym)
          if a.empty?
            dsl_options[m.to_sym]
          else
            dsl_options[m.to_sym] = (a.size > 1) ? a : a[0]
          end          
        else
          raise "You shouldn't be here"
        end
      end
    end
    
    # Check on the forwarders to see if they can handle the methods
    def can_my_chain_handle_the_method?(m)
      forwarders.each do |fwd|
        return true if fwd.respond_to?(:can_i_handle_the_method?) && fwd.can_i_handle_the_method?(m)
        return true if fwd.respond_to?(m.to_sym)
      end
      false
    end
    # Go through the list of forwarders and see if they can handle the method
    # If they can, then let's setup a forwardable delegation so they don't have 
    # to run through this maze again
    def let_my_forwarders_handle_the_method(m)
      forwarders.each do |fwd|
        if fwd.respond_to?(:can_i_handle_the_method?) && fwd.can_i_handle_the_method?(m)
          self.class.class_eval { def_delegator fwd, m.to_sym }
          return fwd.handle_the_method(m) if fwd.respond_to?(:handle_the_method)
        elsif fwd.respond_to?(m)
          self.class.class_eval { def_delegator fwd, m.to_sym }
          return fwd.send(m.to_sym)
        end
      end
      nil
    end
    # Get the value from the dsl_options or the forwarders
    def fetch(m)
      if can_i_handle_the_method?(m)        
        handle_the_method(m)
      elsif can_my_chain_handle_the_method?(m)
        let_my_forwarders_handle_the_method(m)
      else
        raise "The method :#{m} cannot be found on #{self}"
      end
    end
    # Set the value
    # If I can handle the method, then handle the method here first
    # otherwise, check to see if the chain can handle the method.
    # If the chain can handle the method, then create the method on
    # self and get the output
    def set(m, *a, &block)
      m = m.to_sym
      val = a.size > 1 ? a : a[0]
      if can_i_handle_the_method?(m)
        handle_the_method(m, val, &block)
      elsif can_my_chain_handle_the_method?(m)
        o = let_my_forwarders_handle_the_method(m)
        add_method(m)
        self.send m, val, &block
        o
      else
        raise "Cannot set the method #{m}(#{a}) on #{self}"
      end      
    end
    
    def can_i_reach?(m)
      can_i_handle_the_method?(m) || can_my_chain_handle_the_method?(m)
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         Forwardable
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end