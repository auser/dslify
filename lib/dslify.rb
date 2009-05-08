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
class Object
  def self.superclasses
    superclass == Object ? [] : [superclass, superclass.superclasses].flatten
  end
end

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
    def dsl_forwarders
      @dsl_forwarders ||= [default_options, superclasses].flatten
    end
    # Add forwarders
    def forwards_to(*arr)
      arr.each {|a| dsl_forwarders.push a unless dsl_forwarders.include?(a) }
    end
    
    def has_key?(m)
      return true if default_options.has_key?(m)
      dsl_forwarders.each do |fwd|
        return true if fwd.has_key?(m)
      end
      false
    end
    
    def fetch(m)
      if default_options.has_key?(m)
        default_options[m]
      else
        dsl_forwarders.each do |fwd|
          if fwd.has_key?(m)
            o = fwd.fetch(m)
            return o
          end
        end
      end
    end
    
  end
  
  module InstanceMethods
    def initialize(hsh={})
      dsl_options.merge!(hsh)
      dsl_options.each do |k,v| 
        add_method(k.to_sym)
        store(k,v)
      end
    end
    def set_vars_from_options(hsh={})
      puts "set_vars_from_options will be deprecated. Fix your code, foo"
      hsh.each {|k,v| dsl_option(k,v) }
    end
    def dsl_option(k,v=nil)
      add_method(k)
      dsl_options[k] = v
    end
    def dsl_options
      @dsl_options ||= self.class.default_options
    end
    def dsl_methods(*arr)
      ((@dsl_methods ||= self.class.dsl_methods) << arr).flatten
    end
    def dsl_forwarders
      @dsl_forwarders ||= self.class.dsl_forwarders
    end
    def has_key?(m)
      dsl_options.has_key?(m)
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
          store(clean_meth, val, &block)
        end
      end
    end
    
    def add_method(meth)
      instance_eval <<-EOM
        def #{meth}(n=nil)
          if n
            dsl_options[:#{meth}] = n
          else
            o = dsl_options[:#{meth}]            
            o = instance_eval(&o) if o.is_a?(Proc)
            o
          end
        end
        def #{meth}=(n)
          dsl_options[:#{meth}] = n
        end
        def #{meth}?
          ![nil, false].include?(#{meth})
        end
      EOM
    end
    
    # Get the value from the dsl_options or the forwarders
    def fetch(m)
      if respond_to?(:dsl_options) && dsl_options.has_key?(m)
        add_method(m)
        return self.send m
      else
        dsl_forwarders.each do |fwd|
          fwd = self.send(fwd) if fwd.is_a?(Symbol)  
          if fwd.has_key?(m)
            o = fwd.fetch(m)              
            add_method(m)
            o = o.call if o.is_a?(Proc)
            return o
          end
        end
      end
      raise NoMethodError
    end

    # Set the value
    # If I can handle the method, then handle the method here first
    # otherwise, check to see if the chain can handle the method.
    # If the chain can handle the method, then create the method on
    # self and get the output
    def store(m, *a, &block)
      if dsl_options.has_key?(m)
        m = m.to_sym
        val = a.size > 1 ? a : a[0]
        dsl_options[m] = val
      else
        raise NoMethodError
      end
    end
    
    def can_i_reach?(m)
      begin
        fetch(m.to_s.gsub(/\?/, '').to_sym)
        true
      rescue Exception => e
        false
      end
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end