module Dslify
  def self.included(base)
    base.send     :include, InstanceMethods
    base.extend(ClassMethods)
  end
  
  module ClassMethods    
    def default_options(hsh={})
      (@_dsl_options ||= {}).merge! hsh
      set_default_options(@_dsl_options)
    end
    
    def dsl_options
      @_dsl_options ||= {}
    end
    def options
      dsl_options
    end
    
    def dsl_methods(*syms)
      syms.each do |sym|
        hsh = sym.is_a?(Hash) ? {sym[sym.keys.first] => ({:value => nil}).merge(sym)} : {sym => {:value => nil}}
        set_default_options(hsh)
      end
    end
    
    def set_default_options(new_options)
      new_options.each do |k,v|
        if k.is_a?(Hash)
          puts "Creating: #{k.inspect} => #{v.inspect} from #{k.keys.inspect}"
          # dsl_options[k] = v[:value]
          define_dsl_method_str_with_validation(k,v)
        else
          dsl_options[k] = v
        end
        class_eval define_dsl_method_str(k)
      end
    end
    
    def define_dsl_method_str_with_validation(k,val)
      class_eval <<-EOV
        def #{k}=(n)
          dsl_options[:#{k}] = if validation_blocks.has_key?(:#{val}) 
              validation_blocks[#{val}].call(n)
            else
              val
            end
        end
      EOV
      
    end
    
    def define_dsl_method_str(k, ty=nil)
      <<-EOE
        def #{k}(n=nil)
          if n.nil?
            fetch(:#{k})
          else
            self.#{k}=n
          end          
        end
        def #{k}=(n)
          dsl_options[:#{k}] = n          
        end
        def fetch(k)          
          dsl_options[k]
        end
      EOE
    end
    
    def with_type(ty, &block)
      validation_blocks[ty] = block
    end
    
    def validation_blocks
      @validation_blocks ||= {}
    end
    
    def inherited(subclass)
      subclass.set_default_options(dsl_options)
    end
  end
  module InstanceMethods
    def dsl_options
      @dsl_options ||= self.class.dsl_options.clone
    end
    def set_vars_from_options(hsh={})
      hsh.each do |k,v| 
        instance_eval self.class.define_dsl_method_str(k) unless self.respond_to?(k)
        self.send k, v
      end
    end
    
    def set_default_options(hsh={})
      self.class.set_default_options(hsh)
    end
    
    def method_missing(m,*a,&block)
      if m.to_s[-1..-1] == '?'
        t = m.to_s.gsub(/\?/, '').to_sym
        warn "DEPRECATED: Dslify will no longer support ? methods. Fix yo code.: #{m}"
        respond_to?(t) && !self.send(t, *a, &block).nil?
      else
        super
      end
    end
  end
end