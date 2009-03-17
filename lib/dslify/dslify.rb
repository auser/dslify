# Quick 1-file dsl accessor
module Dslify
  module ClassMethods
    def default_options(hsh={})
      @default_dsl_options ||= hsh
    end
  end
  
  module InstanceMethods
    def __h
      @__h||={}
    end
    def default_dsl_options;self.class.default_options;end
    def dsl_options(h=nil)
      if h
        @__h = self.class.default_options.merge(h)
      else
        @__h ||= self.class.default_options
      end
    end
    def set_vars_from_options(h={})
      h.each{|k,v|send k.to_sym, v } unless h.empty?
    end
    def add_method(meth)
      instance_eval <<-EOM 
        def #{meth}(n=nil)
          n ? (__h[:#{meth}] = n) : __h[:#{meth}]
        end
        def #{meth}=(n)
          __h[:#{meth}] = n
        end
      EOM
    end      
    
    def method_missing(m,*a,&block)
      if block
        if a.empty?
          (a[0].class == self.class) ? a[0].instance_eval(&block) : super
        else
          inst = a[0]
          inst.instance_eval(&block)
          add_method(m)
          __h[m] = inst
        end
      else
        if a.empty?
          __h[m]
        else
          add_method(m.to_s.gsub(/\=/,"").to_sym)
          __h[m.to_s.gsub(/\=/,"").to_sym] = (a.size > 1 ? a : a[0])          
        end
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end