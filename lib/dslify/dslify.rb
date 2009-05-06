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
    # Force set a dsl_option
    def dsl_option(k,v)
      dsl_options[k.to_sym] = v
      add_method(k.to_sym)
    end
    alias :options :dsl_options
    def set_vars_from_options(h, contxt=self)
      h.each do |k,v|
        if contxt.respond_to?(k.to_sym)
          contxt.send k.to_sym, v 
        else
          clean_meth = k.to_s.gsub(/\=/,"").to_sym
          dsl_options[clean_meth] = v
          add_method(clean_meth) unless respond_to?(clean_meth)
        end
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
          exists_and_non_nil?(:#{meth})
        end
      EOM
    end
    def exists_and_non_nil?(m)
      if respond_to?(m)
        res = (self.__send__ m)
        !res.nil? && res != false
      elsif respond_to?(:parent) && parent && parent.respond_to?(m)
        parent.__send__ m
      else
        false
      end
    end
    # The power behind 
    def method_missing(m,*a,&block)
      if block
        if a.empty?
          (a[0].class == self.class) ? a[0].instance_eval(&block) : super
        else
          inst = a[0]
          inst.instance_eval(&block)
          dsl_options[m] = inst
          add_method(m)
        end
      else        
        if a.empty?
          if dsl_options.has_key?(m) && o = (dsl_options[m].nil? ? nil : dsl_options[m])
            o
          elsif m.to_s.index("?") == (m.to_s.length - 1)
            # if options.has_key?(val = m.to_s.gsub(/\?/, '').to_sym) && options[val]
            #   options[val] != false
            # elsif respond_to?(:parent) && parent.respond_to?(m)
            #   parent.__send__ m
            # else
            #   false
            # end
            exists_and_non_nil?(m.to_s.gsub(/\?/, '').to_sym)
          else            
            if self.class.superclass.respond_to?(:default_options) && self.class.superclass.default_options.has_key?(m)
              self.class.superclass.default_options[m]
            elsif ((respond_to? :parent) && !parent.nil? && (parent != self))
              parent.send m, *a, &block
            else
              super
            end
          end
        else
          clean_meth = m.to_s.gsub(/\=/,"").to_sym
          val = a.size > 1 ? a : a[0]
          if m.to_s.include?("=")
            dsl_options[clean_meth] = val
          else
            if dsl_options.has_key?(clean_meth)
              dsl_options[clean_meth] = val              
            elsif self.class.respond_to?(:default_options) && self.class.default_options.has_key?(clean_meth)
              dsl_options[clean_meth] = val
            elsif self.class.superclass.respond_to?(:default_options) && self.class.superclass.default_options.has_key?(clean_meth)
              dsl_options[clean_meth] = val
            else
              raise "No method exists #{clean_meth}(#{a}) on #{self}"
            end
          end
          add_method(clean_meth)
        end
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end