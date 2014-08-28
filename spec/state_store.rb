
shared_examples_for "State Store" do
  [
    :error_count,
    :increment_error_count,
    :get_state,
    :get_last_trip_time,
    :reset,
    :open,
    :attempt_reset
  ].each do |required_method|
    it { is_expected.to respond_to(required_method).with(1).argument }
  end

  it "sets error count" do
    store.increment_error_count(:foo)
    expect(store.error_count(:foo)).to eq(1)
  end

  it "is initialized with state :closed" do
    expect(store.get_state(:foo)).to eq(:closed)
  end

  it "is initialized with last_trip_time nil" do
    expect(store.get_last_trip_time(:foo)).to eq(nil)
  end

  it "sets last_trip_time to current time when opened" do
    now = Time.now
    Timecop.freeze(now)
    store.open(:foo)

    expect(store.get_last_trip_time(:foo)).to eq(DateTime.parse(Time.now.to_datetime.iso8601).to_time)
  end

  it "when opened, sets state to open" do
    store.open(:foo)

    expect(store.get_state(:foo)).to eq(:open)
  end

  it "sets state to half_open on attempt_reset" do
    store.attempt_reset(:foo)

    expect(store.get_state(:foo)).to eq(:half_open)
  end

  it "does not touch last_trip_time on attempt_reset" do
    now = Time.now
    Timecop.freeze(now)
    store.open(:foo)

    store.attempt_reset(:foo)

    expect(store.get_last_trip_time(:foo)).to eq(DateTime.parse(Time.now.to_datetime.iso8601).to_time)
  end

  it "when reset, sets error count to 0" do
    store.increment_error_count(:foo)

    store.reset(:foo)

    expect(store.error_count(:foo)).to eq(0)
  end

  it "when reset, sets state to closed" do
    store.open(:foo)

    store.reset(:foo)

    expect(store.get_state(:foo)).to eq(:closed)
  end

  it "when reset, sets last_trip_time to nil" do
    store.open(:foo)

    store.reset(:foo)

    expect(store.get_last_trip_time(:foo)).to eq(nil)
  end

end
