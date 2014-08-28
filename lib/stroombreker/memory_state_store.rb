module Stroombreker
  class MemoryStateStore
    def initialize
      @states = Hash.new { |hash, key|  hash[key] = { error_count: 0, state: :closed, last_trip_time: nil } }
    end

    def error_count(name)
      @states[name][:error_count]
    end

    def increment_error_count(name)
      @states[name][:error_count] += 1
    end

    def get_state(name)
      @states[name][:state]
    end

    def get_last_trip_time(name)
      time = @states[name][:last_trip_time]
      return nil if time.nil?
      DateTime.parse(time).to_time
    end

    def reset(name)
      @states[name] = {
        error_count: 0,
        state: :closed,
        last_trip_time: nil
      }
    end

    def open(name)
      @states[name][:last_trip_time] = Time.now.iso8601
      @states[name][:state] = :open
    end

    def attempt_reset(name)
      @states[name][:state] = :half_open
    end
  end
end
