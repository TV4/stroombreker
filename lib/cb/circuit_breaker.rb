class Cb::CircuitBreaker
  def initialize(opts)
    @threshold = opts[:threshold]
    @state = :closed
    @last_trip_time = nil
    @error_count = 0
  end

  def execute(&block)
    update_state

    raise Cb::CircuitBrokenException if @state == :open

    do_execute(&block)
  end

  private

  def do_execute
    yield
  rescue => e
    @error_count += 1
    if @error_count > @threshold
      open
      raise Cb::CircuitBrokenException
    else
      raise
    end
  end

  def update_state
    if @state == :open && @last_trip_time + 10 < Time.now
      @state = :half_open
    end
  end

  def open
    @last_trip_time = Time.now
    @state = :open
  end
end
