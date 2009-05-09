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
      @default_options.each {|k,v| create_method_on(self, k) }
    end
    # For every method, add a default of nil to the default_options hash
    def dsl_methods(*arr)
      arr.each {|a| default_options({a => nil}) }
    end
    def forwards_to(consts=[])
      (dsl_forwarders << consts).flatten
    end
    def dsl_forwarders
      @dsl_forwarders ||= []
    end
    def dsl_option(k,v=nil)
      create_method_on(self, k)
      default_options.merge!({k => v})
    end
    def inherited(receiver)
      default_options.each{|k,v| create_method_on(receiver, k)}
      receiver.default_options.merge!(default_options)
      (receiver.dsl_forwarders << dsl_forwarders).flatten!
    end
    def create_method_on(on, k)
      str = %{
        def #{k}(n=nil);n.nil? ? __dsl_fetch(:#{k}) : dsl_options[:#{k}] = n;end
        def #{k}=(n=nil);n.nil? ? __dsl_fetch(:#{k}) : dsl_options[:#{k}] = n;end
        def self.#{k}(n=nil);n.nil? ? __dsl_fetch(:#{k}) : default_options[:#{k}] = n;end
        def #{k}?;dsl_options.has_key?(:#{k});end
        }
      on.class_eval str
    end
    def __dsl_fetch(m)
      o = default_options[m]
      case o
      when Proc
        instance_eval &o
      else
        o
      end
    end
  end
  
  module InstanceMethods
    def dsl_options
      @dsl_options ||= self.class.default_options
    end
    def dsl_option(k,v=nil)
      self.class.dsl_option(k,v)
    end
    def dsl_methods(*arr)
      ((@dsl_methods ||= self.class.dsl_methods) << arr).flatten
    end
    def dsl_forwarders
      @dsl_forwarders ||= self.class.dsl_forwarders
    end
    def __dsl_fetch(m)
      o = dsl_options[m]
      case o
      when Proc
        instance_eval &o
      else
        o
      end
    end
    def set_vars_from_options(hsh={})
      hsh.each {|k,v| dsl_option(k,v)}
    end
    
    def method_missing(m,*a,&block)      
      if m.to_s.include?("?")
        dsl_options.has_key?(m.to_s.gsub(/\?/, '').to_sym)
      else
        dsl_forwarders.each do |fwd|
          if fwd.respond_to?(m)
            return fwd.send(m,*a,&block)
          end
        end
        super
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         Forwardable
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end