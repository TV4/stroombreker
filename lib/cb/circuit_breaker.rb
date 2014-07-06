class Cb::CircuitBreaker
  def initialize(opts)
    @state = :closed
    @last_failure_time = nil
  end

  def execute
    if @state == :open
      if @last_failure_time + 10 < Time.now
        yield
      else
        raise Cb::CircuitBrokenException
      end
    end
    yield
  rescue => e
    open
    raise Cb::CircuitBrokenException
  end

  private
  def open
    @last_failure_time = Time.now
    @state = :open
  end
end
