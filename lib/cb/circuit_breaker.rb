class Cb::CircuitBreaker
  def initialize(opts)
    @state = :closed
  end

  def execute
    raise Cb::CircuitBrokenException if @state == :open
    yield
  rescue => e
    open
    raise Cb::CircuitBrokenException
  end

  private
  def open
    @state = :open
  end
end
