# Quick 1-file dsl accessor
module Dslify
  module ClassMethods
    def default_options(hsh={})
      @default_dsl_options ||= hsh
    end
  end
  
  module InstanceMethods
    def default_dsl_options;self.class.default_options;end
    def dsl_options(hsh={})
      @dsl_options ||= default_dsl_options.merge(hsh)
    end
    alias :options :dsl_options
    def set_vars_from_options(h, contxt=self)
      h.each do |k,v| 
        if contxt.respond_to?(k.to_sym)
          contxt.send k.to_sym, v 
        else
          clean_meth = k.to_s.gsub(/\=/,"").to_sym
          dsl_options[clean_meth] = v
        end        
      end
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
          if dsl_options.has_key?(m)
            dsl_options[m]
          elsif m.to_s.index("?") == (m.to_s.length - 1)
            if options.has_key?(val = m.to_s.gsub(/\?/, '').to_sym)
              options[val] != false
            else
              false
            end
          else
            if self.class.superclass.respond_to?(:default_options) && self.class.superclass.default_options.has_key?(m)
              self.class.superclass.default_options[m]
            elsif ((respond_to? :parent) && (parent != self))
              parent.send m, *a, &block
            else
              super
            end
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