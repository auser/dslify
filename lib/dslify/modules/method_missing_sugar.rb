module Dslify
  module MethodMissingSugar

    def method_missing(m, *args, &block)
      if block_given?
        (args[0].class == self.class) ? args[0].run_in_context(&block) : super
      else
        get_from_options(m, *args, &block)
      end
    end

    def get_from_options(m, *args, &block)
      if args.empty?
        __options.has_key?(m) ? __options[m] : nil
      else
        __options[m] = (args.is_a?(Array) && args.size > 1) ? args : args[0]
      end
    end
    
  end
end