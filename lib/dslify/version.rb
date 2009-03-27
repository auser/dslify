module Dslify
  module VERSION #:nodoc:
    MAJOR = 0 unless const_defined?("MAJOR")
    MINOR = 0 unless const_defined?("MINOR")
    TINY  = 4 unless const_defined?("TINY")

    STRING = [MAJOR, MINOR, TINY].join('.') unless const_defined?("STRING")
    self
  end
end
