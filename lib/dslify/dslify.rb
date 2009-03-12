# Quick 1-file dsl accessor
class Object  
  def h
    @h||={}
  end
  def set_vars_from_options(h={})
    h.each{|k,v|send k.to_sym, v } unless h.empty?
  end
  def method_missing(m,*a,&block)
    if block
      ((a[0].class==self.class)?a[0].instance_eval(&block): super)
    else
      ((a.empty?)?h[m]:h[m.to_s.gsub(/\=/,"").to_sym]=(a.size>1?a:a[0]))
    end
  end
end
