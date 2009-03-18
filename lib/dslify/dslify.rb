# Quick 1-file dsl accessor
module Dslify
  module ClassMethods
    def default_options(hsh={})
      @default_dsl_options ||= hsh
    end
  end
  
  module InstanceMethods
    def __h(hsh={})
      @__h ||= hsh
    end
    def default_dsl_options;self.class.default_options;end
    def dsl_options(h=nil)
      if h
        @__h = self.class.default_options.merge(h)
      else
        __h(self.class.default_options)
      end
    end
    alias :options :dsl_options
    def set_vars_from_options(h={})
      h.each{|k,v|send k.to_sym, v } unless h.empty?
    end
    def add_method(meth)
      # instance_eval <<-EOM        
      #   def #{meth}(n=nil)
      #     puts "called #{meth}(\#\{n\}) from \#\{self\}"
      #     n ? (__h[:#{meth}] = n) : __h[:#{meth}]
      #   end
      #   def #{meth}=(n)
      #     __h[:#{meth}] = n
      #   end
      # EOM
    end
    def method_missing(m,*a,&block)
      if block
        if a.empty?
          (a[0].class == self.class) ? a[0].instance_eval(&block) : super
        else
          inst = a[0]
          inst.instance_eval(&block)
          __h[m] = inst
        end
      else
        if a.empty?
          __h[m.to_sym]
        else
          clean_meth = m.to_s.gsub(/\=/,"").to_sym
          __h[clean_meth] = (a.size > 1 ? a : a[0])          
        end
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end