require "stroombreker/version"

module Stroombreker
  def self.register(breaker_args)
    @breakers ||= {}
    breaker = Stroombreker::CircuitBreaker.new(breaker_args)
    @breakers[breaker.name] = breaker
  end

  def self.[](name)
    @breakers.fetch(name) {
      raise ArgumentError, "Unregistered Cicuit breaker #{name}. Available: #{@breakers.keys.join(" ,")}"
    }
  end

  def self.all
    @breakers.values
  end

  def self.store
    @store ||= MemoryStateStore.new
  end

  def self.store=(store)
    @store = store
  end
end

class Stroombreker::CircuitBrokenException < StandardError; end 

require "stroombreker/circuit_breaker"
require "stroombreker/memory_state_store"
require "stroombreker/redis_state_store"

