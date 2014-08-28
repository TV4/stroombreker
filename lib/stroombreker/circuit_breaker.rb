class Stroombreker::CircuitBreaker

  attr_reader :threshold, :error_count, :half_open_timeout
  def initialize(opts)
    @threshold = opts.fetch(:threshold)
    @half_open_timeout = opts.fetch(:half_open_timeout)
    @name = opts.fetch(:name)
    @state_store = opts.fetch(:state_store)
    @last_trip_time = nil
  end

  def execute(&block)
    update_state

    raise Stroombreker::CircuitBrokenException if open?

    do_execute(&block)
  end

  private

  def do_execute
    execution_result = yield
  rescue => e
    if closed?
      @state_store.increment_error_count(@name)
      if @state_store.error_count(@name) > threshold
        open
        raise Stroombreker::CircuitBrokenException
      else
        raise
      end
    elsif half_open?
      open
      raise
    end
  else
    reset
    execution_result
  end

  def update_state
    if open? && @last_trip_time + half_open_timeout < Time.now
      attemt_reset
    end
  end

  def open
    @last_trip_time = Time.now
    @state_store.set_state(@name, :open)
  end

  def attemt_reset
    @state_store.set_state(@name, :half_open)
  end

  def reset
    @state_store.set_state(@name, :closed)
    @state_store.reset_error_count(@name)
    @last_trip_time = nil
  end

  def open?
    state == :open
  end

  def closed?
    state == :closed
  end

  def half_open?
    state == :half_open
  end

  def state
    @state_store.get_state(@name)
  end
end
