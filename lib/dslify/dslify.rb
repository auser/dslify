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
    def dsl_options(hsh={})
      @dsl_options ||= default_dsl_options.merge(hsh)
    end
    alias :options :dsl_options
    def set_vars_from_options(h={})
      h.each{|k,v| dsl_options[k] = v } unless h.empty?
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
          dsl_options[m] = inst
        end
      else
        if a.empty?
          # puts "dsl_options[m.to_sym]: #{dsl_options[m.to_sym] ? dsl_options[m.to_sym] : super} (#{self})"
          # dsl_options[m.to_sym]
          if options.has_key?(m) 
            options[m]
          else 
            self.class.superclass.respond_to?(:default_options) ? self.class.superclass.default_options[m] : super
          end
        else
          clean_meth = m.to_s.gsub(/\=/,"").to_sym
          dsl_options[clean_meth] = (a.size > 1 ? a : a[0])          
        end
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end