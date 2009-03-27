module Dslify
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 0
    TINY  = 4

    STRING = [MAJOR, MINOR, TINY].join('.') unless const_defined?("STRING")
    self
  end
end
