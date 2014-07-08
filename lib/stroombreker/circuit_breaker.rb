class Stroombreker::CircuitBreaker
  class MemoryStateStore
    def initialize
      @error_count = 0
    end

    def error_count
      @error_count
    end

    def increment_error_count
      @error_count += 1
    end

    def reset_error_count
      @error_count = 0
    end
  end

  attr_reader :threshold, :error_count, :half_open_timeout
  def initialize(opts)
    @threshold = opts.fetch(:threshold)
    @half_open_timeout = opts.fetch(:half_open_timeout)
    @state = :closed
    @state_store = MemoryStateStore.new
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
      @state_store.increment_error_count
      if @state_store.error_count > threshold
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
    @state = :open
  end

  def attemt_reset
    @state = :half_open
  end

  def reset
    @state = :closed
    @state_store.reset_error_count
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
