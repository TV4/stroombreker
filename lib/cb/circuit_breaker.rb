class Cb::CircuitBreaker
  def initialize(opts)
    @state = :closed
    @last_failure_time = nil
  end

  def execute
    update_state

    if @state == :open
      raise Cb::CircuitBrokenException
    end

    yield
  rescue => e
    open
    puts e
    raise Cb::CircuitBrokenException
  end

  private

  def update_state
    if @state == :open && @last_failure_time + 10 < Time.now
      @state = :half_open
    end
  end

  def open
    @last_failure_time = Time.now
    @state = :open
  end
end
