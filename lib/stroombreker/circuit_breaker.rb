class Stroombreker::CircuitBreaker

  attr_reader :threshold, :error_count, :half_open_timeout
  def initialize(opts)
    @threshold = opts.fetch(:threshold)
    @half_open_timeout = opts.fetch(:half_open_timeout)
    @name = opts.fetch(:name)
    @state_store = opts.fetch(:state_store)
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
    if open? && @state_store.get_last_trip_time(@name) + half_open_timeout < Time.now
      attemt_reset
    end
  end

  def open
    @state_store.open(@name)
  end

  def attemt_reset
    @state_store.attempt_reset(@name)
  end

  def reset
    @state_store.reset(@name)
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
