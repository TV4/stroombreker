class Cb::CircuitBreaker
  attr_reader :threshold, :error_count, :half_open_timeout
  def initialize(opts)
    @threshold = opts.fetch(:threshold)
    @half_open_timeout = opts.fetch(:half_open_timeout)
    @state = :closed
    @last_trip_time = nil
    @error_count = 0
  end

  def execute(&block)
    update_state

    raise Cb::CircuitBrokenException if open?

    do_execute(&block)
  end

  private

  def do_execute
    ret = yield
    reset
    ret
  rescue => e
    if closed?
      @error_count += 1
      if error_count > threshold
        open
        raise Cb::CircuitBrokenException
      else
        raise
      end
    elsif half_open?
      open
      raise
    end
  end

  def update_state
    if open? && @last_trip_time + half_open_timeout < Time.now
      half_reset
    end

  end

  def open
    @last_trip_time = Time.now
    @state = :open
  end

  def half_reset
    @state = :half_open
  end

  def reset
    @state = :closed
    @error_count = 0
    @last_trip_time = nil
  end

  def open?
    @state == :open
  end

  def closed?
    @state == :closed
  end

  def half_open?
    @state == :half_open
  end
end
