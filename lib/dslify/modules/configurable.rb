module Dslify
  module Configurable
    module ClassMethods      
      def default_options(h={})
        @default_options ||= h
      end
    end
    
    module InstanceMethods
      def __options(h={})
        @__options ||= self.class.default_options.merge(h)
      end
      
      def configure(h={})
        __options(h).merge!(h)
      end
      
      def reconfigure(h={})
        @__options = nil
        __options(h)
      end
      
      def set_vars_from_options(opts={})
        opts.each {|k,v| self.send k.to_sym, v } unless opts.empty?
      end
      
      def dsl_options_keys
        __options.keys
      end
      def dsl_options
        __options
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end