require "stroombreker/version"

module Stroombreker; end

class Stroombreker::CircuitBrokenException < StandardError; end 

require "stroombreker/circuit_breaker"
require "stroombreker/memory_state_store"
require "stroombreker/redis_state_store"

