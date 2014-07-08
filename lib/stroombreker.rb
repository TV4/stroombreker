require "stroombreker/version"

module Stroombreker; end

class Stroombreker::CircuitBrokenException < StandardError; end 

require "stroombreker/circuit_breaker"

