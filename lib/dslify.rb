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
      @default_options.each {|k,v| create_method_on(self, k) }
    end
    # For every method, add a default of nil to the default_options hash
    def dsl_methods(*arr)
      arr.each {|a| default_options({a => nil}) }
    end
    def create_method_on(on, k)
      str = %{
        def #{k}(n=nil);n.nil? ? __dsl_fetch(:#{k}) : dsl_options[:#{k}] = n;end
        def #{k}=(n=nil);n.nil? ? __dsl_fetch(:#{k}) : dsl_options[:#{k}] = n;end
        def #{k}?;o = self.send(:#{k}); !o.nil? && o;end
        }
        # dsl_options.has_key?(:#{k}) and !dsl_options[:#{k}].nil?
      on.class_eval str
    end
  end
  
  module InstanceMethods
    def dsl_options(hsh=nil)
      hsh ? __dsl_options.merge!(hsh) : __dsl_options
    end
    def __dsl_options(hsh={})
      @dsl_options ||= self.class.default_options.dup
    end
    alias :options :dsl_options
    
    def dsl_option(k,v=nil)
      self.class.create_method_on(self, k) unless respond_to?(k)
      dsl_options[k.to_sym] = v
    end
    
    def dsl_methods(*arr)
      ((@dsl_methods ||= self.class.dsl_methods) << arr).flatten
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
      hsh.each do |k,v|
        if self.respond_to?(k)
          self.send k, v
        elsif
          dsl_option(k,v)
        end
      end
    end
    def method_missing(m,*a,&block)
      if m.to_s.include?("?")
        o = (self.send m.to_s.gsub(/\?/, '').to_sym)
        !o.nil? && o
      else
        super
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end