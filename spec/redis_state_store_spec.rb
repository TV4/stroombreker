require "stroombreker"
require "timecop"
require "mock_redis"
require_relative "state_store"

describe Stroombreker::RedisStateStore do
  let(:redis) { MockRedis.new }
  subject(:store) { Stroombreker::RedisStateStore.new(redis) }

  it_should_behave_like "State Store"
end
