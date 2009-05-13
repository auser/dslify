module Dslify
  def self.included(base)
    base.send     :include, InstanceMethods
    base.extend(ClassMethods)
  end
  
  module ClassMethods    
    def default_options(hsh)
      (@_dsl_options ||= {}).merge! hsh
      set_default_options(@_dsl_options)
    end
    
    def dsl_options
      @_dsl_options ||= {}
    end
    
    def dsl_methods(*syms)
      syms.each {|sym| set_default_options({sym => nil}) }
    end
    
    def set_default_options(new_options)
      new_options.each do |k,v|
        dsl_options[k] = v
        class_eval define_dsl_method_str(k)
      end
    end
    
    def define_dsl_method_str(k)
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
          o = dsl_options[k]
          case o
          when Proc
            dsl_options[k] = o.call
          else
            o
          end                      
        end
      EOE
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
      hsh.each {|k,v| instance_eval self.class.define_dsl_method_str(k);dsl_options[k] = v}
    end
    def method_missing(m,*a,&block)
      if m.to_s =~ /\?$/
        warn "DEPRECATED: Dslify will no longer support ? methods. Fix yo code"
        respond_to?(m.to_s.gsub(/\?/, '').to_sym)
      else
        super
      end
    end
  end
end