class Object
  def vputs(m="", o=self)
    puts m if o.verbose rescue ""
  end
  def returning(receiver)
    yield receiver
    receiver
  end
  def run_in_context(context=self, &block)
    name="temp_#{self.class}_#{respond_to?(:parent) ? parent.to_s : Time.now.to_i}".to_sym
    meta_def name, &block
    self.send name, context
    meta_undef name rescue ""
  end  
end