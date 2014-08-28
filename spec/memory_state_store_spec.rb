require "stroombreker"
require "timecop"
require_relative "state_store"

describe Stroombreker::MemoryStateStore do
  subject(:store) { Stroombreker::MemoryStateStore.new }

  it_should_behave_like "State Store"
end
