$: << Pathname(__FILE__) + ".." + ".." + "lib"

require "stroombreker"
require "timecop"
require "pry"
require "active_support/core_ext/numeric/time"

describe "CircuitBreaker" do
  after do
    Timecop.return
  end

  it "passes response value back when everything works" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 0, half_open_timeout: 10)

    value = cb.execute do
      "simulated api call"
    end

    expect(value).to eq("simulated api call")
  end

  it "returns the cause exception if within threshold" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    expect {
      cb.execute(&failing_work)
    }.to raise_error(/something/)
  end

  it "second call raises CircuitBrokenException" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    with_expected_underlying_error { cb.execute(&failing_work) }

    expect {
      cb.execute(&failing_work)
    }.to raise_error(Stroombreker::CircuitBrokenException)
  end

  it "never calls work block when circuit is broken" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 0, half_open_timeout: 10)

    called = false
    work_spy = ->() { called = true }

    with_expected_broken_circuit { cb.execute(&failing_work) }
    with_expected_broken_circuit { cb.execute(&work_spy) }

    expect(called).to eq(false)
  end

  it "returns the value in half-open" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    with_expected_underlying_error { cb.execute(&failing_work) }
    with_expected_broken_circuit { cb.execute(&failing_work) }

    Timecop.travel(11.seconds.from_now)

    value = cb.execute(&working_work)

    expect(value).to eq("simulated api call")
  end

  it "raises error in half-open" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    with_expected_underlying_error { cb.execute(&failing_work) }
    with_expected_broken_circuit { cb.execute(&failing_work) }

    Timecop.travel(11.seconds.from_now)

    expect {
      cb.execute(&failing_work)
    }.to raise_error(/something/)
  end

  it "immediatly goes back to open" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 10)

    with_expected_underlying_error { cb.execute(&failing_work) }
    with_expected_broken_circuit { cb.execute(&failing_work) }

    Timecop.travel(11.seconds.from_now)

    with_expected_underlying_error { cb.execute(&failing_work) }

    work_called = false
    work_spy = ->() { work_called = false }
    with_expected_broken_circuit { cb.execute(&work_spy) }

    expect(work_called).to eq(false)
  end

  it "switches to closed after timeout seconds of working stuff" do
    cb = Stroombreker::CircuitBreaker.new(threshold: 1, half_open_timeout: 20)

    with_expected_underlying_error { cb.execute(&failing_work) }
    with_expected_broken_circuit { cb.execute(&failing_work) }

    Timecop.travel(21.seconds.from_now)

    expect {
      cb.execute(&failing_work)
    }.to raise_error(/something/)

    expect {
      cb.execute(&failing_work)
    }.to raise_error(Stroombreker::CircuitBrokenException)
  end

  it "stays closed after exception withint threshold"
  it "keep the nested exception"


  def with_expected_broken_circuit
    yield
    raise "expected a raised CircuitBrokenException, but didn't get it"
  rescue Stroombreker::CircuitBrokenException
    # ignore, since we expect this exception
  end

  def with_expected_underlying_error(&block)
    block.call
  rescue Stroombreker::CircuitBrokenException => e
    # We expect an underlying exception, not a CircuitBrokenException
    raise "Unexpected CircuitBrokenException"
  rescue
    # Ignore, since it is expected
  end

  def failing_work
    ->() { raise "something" }
  end

  def working_work
    ->() { "simulated api call" }
  end
end
