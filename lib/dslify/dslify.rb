# Quick 1-file dsl accessor
class Object  
  def h
    @h||={}
  end
  def dsl_options;h;end
  def set_vars_from_options(h={})
    h.each{|k,v|send k.to_sym, v } unless h.empty?
  end
  def method_missing(m,*a,&block)
    if block
      if args.empty?
        (a[0].class == self.class) ? a[0].instance_eval(&block) : super
      else
        inst = a[0]
        inst.instance_eval(&block)
        h[m] = inst
      end
    else
      if a.empty?
        h[m]
      else
        h[m.to_s.gsub(/\=/,"").to_sym] = (a.size > 1 ? a : a[0])
      end
    end
  end
end
