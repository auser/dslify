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
        options.has_key?(m) ? options[m] : nil
      else
        options[m] = 
        if (args.is_a?(Array) && args.size > 1)
          args
        else
          args[0]
        end
      end
    end
    
  end
end