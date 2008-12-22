module Dslify
  module MethodMissingSugar

    def method_missing(m, *args, &block)
      if block_given?
        (args[0].class == self.class) ? args[0].run_in_context(&block) : super
      else
        get_from_options(m.to_s, *args, &block)
      end
    end

    def get_from_options(meth, *args, &block)
      key = meth.include?("=") ? meth.delete("=") : meth
      sym_key = key.to_sym
      if args.empty?
        __options.has_key?(sym_key) ? __options[sym_key] : nil
      else
        __options[sym_key] = (args.is_a?(Array) && args.size > 1) ? args : args[0]
      end
    end
    
  end
end