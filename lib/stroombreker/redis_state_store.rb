class Stroombreker::RedisStateStore
  def initialize(redis)
    @redis = redis
  end

  def error_count(name)
    @redis.get(key_for(name, :error_count)).to_i
  end

  def increment_error_count(name)
    @redis.incr(key_for(name, :error_count))
  end

  def get_state(name)
    state = @redis.get(key_for(name, :state))
    if state.nil?
      :closed
    else
      state.to_sym
    end
  end

  def get_last_trip_time(name)
    time = @redis.get(key_for(name, :last_trip_time))
    return nil if time.nil? || time == ""

    DateTime.parse(time).to_time
  end

  def reset(name)
    @redis.set(key_for(name, :error_count), 0)
    @redis.set(key_for(name, :last_trip_time), nil)
    @redis.set(key_for(name, :state), :closed)
  end

  def open(name)
    time = Time.now.to_datetime.iso8601
    @redis.set(key_for(name, :last_trip_time), time)
    @redis.set(key_for(name, :state), :open)
  end

  def attempt_reset(name)
    @redis.set(key_for(name, :state), :half_open)
  end

  private

  def key_for(name, key_part)
    "stroombreker:#{name}:#{key_part}"
  end
end
