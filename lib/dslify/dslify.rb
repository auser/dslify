# Quick 1-file dsl accessor
module Dslify
  class Base
    def self.default_options(hsh={})
      @default_dsl_options ||= hsh
    end
    def dsl_options(hsh={})
      @dsl_options ||= default_dsl_options.merge(hsh)
    end
    alias :options :dsl_options
    
    def default_dsl_options;self.class.default_options;end    

    def set_vars_from_options(h={})
      h.each{|k,v| dsl_options[k] = v } unless h.empty?
    end
    def add_method(meth)
      # instance_eval <<-EOM        
      #   def #{meth}(n=nil)
      #     puts "called #{meth}(\#\{n\}) from \#\{self\}"
      #     n ? (dsl_options[:#{meth}] = n) : dsl_options[:#{meth}]
      #   end
      #   def #{meth}=(n)
      #     dsl_options[:#{meth}] = n
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
          dsl_options[m.to_sym]
        else
          clean_meth = m.to_s.gsub(/\=/,"").to_sym
          dsl_options[clean_meth] = (a.size > 1 ? a : a[0])          
        end
      end
    end
  end
end