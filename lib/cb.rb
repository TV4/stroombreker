require "cb/version"

module Cb; end

class Cb::CircuitBrokenException < StandardError; end 

require "cb/circuit_breaker"

