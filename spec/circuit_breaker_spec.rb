$: << Pathname(__FILE__) + ".." + ".." + "lib"

require "cb"
require "timecop"
require "pry"
require "active_support/core_ext/numeric/time"

describe "CircuitBreaker" do
  after do
    Timecop.return
  end

  it "passes response value back when everything works" do
    cb = Cb::CircuitBreaker.new(threshold: 0)

    value = cb.execute do
      "simulated api call"
    end

    expect(value).to eq("simulated api call")
  end

  it "returns the cause exception if within threshold" do
    cb = Cb::CircuitBreaker.new(threshold: 1)

    failing_work = ->() { raise "something" }

    expect {
      cb.execute(&failing_work)
    }.to raise_error(/something/)
  end

  it "stays closed after exception withint threshold"

  it "second call raises CircuitBrokenException" do
    cb = Cb::CircuitBreaker.new(threshold: 1)

    begin
      cb.execute do
        raise "something"
      end
    rescue; end

    expect {
      cb.execute do
        raise "something"
      end
    }.to raise_error(Cb::CircuitBrokenException)
  end

  it "never calls work block when circuit is broken" do
    cb = Cb::CircuitBreaker.new(threshold: 0)

    first_failing_work = ->() { raise "something" }
    called = false
    second_work = ->() { called = true }

    with_expected_broken_circuit {
      cb.execute(&first_failing_work)
    }

    with_expected_broken_circuit {
      cb.execute(&second_work)
    }

    expect(called).to eq(false)
  end

  it "keep the nested exception"

  it "returns the value in half-open" do
    cb = Cb::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    work_with_error = ->() {
      raise "Something went wrong"
    }

    successful_work = ->() {
      "simulated response"
    }

    begin
      cb.execute(&work_with_error) # raises, cb opens
    rescue; end
    with_expected_broken_circuit {
      cb.execute(&work_with_error) # raises, cb opens
    }

    Timecop.travel(11.minutes.from_now)

    value = cb.execute(&successful_work) # works, cb in half-open, returns value

    expect(value).to eq("simulated response")

    #cb.stuff(&work_with_error) # raises, cb closes again
    #cb.stuff(&successful_work) # cb open, insta-fails
  end

  it "raises error in half-open" do
    cb = Cb::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    work_with_error = ->() {
      raise "Something went wrong"
    }

    begin
      cb.execute(&work_with_error) # raises, cb opens
    rescue; end
    with_expected_broken_circuit {
      cb.execute(&work_with_error)
    }

    Timecop.travel(11.minutes.from_now)

    expect {
      cb.execute(&work_with_error)
    }.to raise_error(Cb::CircuitBrokenException)
  end

  it "immediatly goes back to open"

  def with_expected_broken_circuit
    yield
    raise "expected a raised CircuitBrokenException, but didn't get it"
  rescue Cb::CircuitBrokenException
    # ignore, since we expect this exception
  end

  xit "switches to closed after timeout seconds of working stuff" do
    # close_timeout: Tiden mellan att cb gått till halv-öppen till stängd
    # half_open_timeout: Tiden mellan att cb öppnas till att den går till halv-öppen
    cb = CircuitBreaker.new(threshold: 1, half_open_timeout: 40, close_timeout: 20)

    simulated_work = ->() {
      raise "something"
    }

    cb.stuff(&simulated_work) # Raises, cb opens
    # Move 41s forward in time
    # cb now in half-open state
    # Move 21s forward in time
    cb.stuff(&simulated_work) # Raises "something" (not CircuitBrokenException)
  end
end
