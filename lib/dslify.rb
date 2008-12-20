$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

Dir["#{File.dirname(__FILE__)}/dslify/*.rb"].each {|f| require f }

module Dslify
  def self.included(base)
    %w(Configurable MethodMissingSugar).each do |inc|
      base.send :include, "Dslify::#{inc}".constantize
    end
  end
end