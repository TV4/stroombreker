# Stroombreker

A simple implementation of the Circuit Breaker pattern from
Michael T. Nygards book "Release it!".

## Features

- As little metaprogramming as possible
- Simple and explicit usage

## Installation

Add this line to your application's Gemfile:

    gem 'stroombreker', git: "https://github.com/tv4/stroombreker"

And then execute:

    $ bundle

## Usage

This is a gem implementing a simple variant of the Circuit Breaker pattern 
described in the book "Release it!" by Michael T. Nygard. 

A circuit breaker is a "thing" that sits at an integration between your application
and some backend application to make sure that if the backend app misbehaves, it wont
take the whole system with it. 

For example, if Web Application A requests some data from Backend B, and B suddenly becomes
slow, it will keep threads/processes in A busy just waiting, which in some cases will kill
A. 

The Circuit Breaker keeps this kind of cascading failures from happening by
"breaking the circuit" if there are too many errors. All calls to the circuit
breaker after this will just throw an error without even trying to call to the
backend application. This is called tripping the breaker, and will put the 
breaker in the `open` state.

After a configurable timeout, the breaker will be put in the `half-open` state.
If the first request after being put in this state fails, it will immediatly
return to `open` state, again not letting request go through for some time.
If the request succeeds, the breaker returns to its original `closed` state.

### Example

````ruby
require "stroombreaker"
require "http_lib"

# Register a circuit breaker
Stroombreker.register(
    threshold: 1,                            # The number of errors before
                                             # tripping the breaker.
    half_open_timeout: 10                    # The number of seconds before
                                             # the breaker returns to 
                                             # half-open state.
    name: :my_breaker                        # The name of the breaker. See
                                             # persistence below.
)
````

The arguments to `.register` is passed to the constructor of
`Stroombreker::CircuitBreaker`.

````ruby
# Find a registered breaker
breaker = Stroombreker[:my_breaker]

# Execute some code through the breaker
result = breaker.execute {
    HttpLib.get("http://possibly-slow-backend/endpoint", timeout: 1.second)
}
````

Now a number of things might happen.

- The breaker is in `closed` state
    - The http call succeeds: The response is returned from `breaker.execute`.
    - The http call fails (Raises an exception): The breaker keeps track of the
      number of errors occurred. If it reached the threshold,
      `Stroombreker::CircuitBrokenException` is raised and the breaker is moved
      to `open` state.
- The breaker is in `closed` state. A `Stroombreker::CircuitBrokenException`
  exception will be raised immediatly. The block is never called
- The breaker is in `half-open` state. The call is made and depending on response:
    - call succeeds: Breaker state moves to `closed` and response is returned
    - call fails: Breaker state moves to open and
      `Stroombreker::CircuitBrokenException` is raised

Note that Stroombreker doesn't care at all about the return value of the block,
only about exceptions. This means that it is the responsibility of the block
to make sure that errors raises an exception if there is an error condition. For
example, some HTTP libraries doesn't raise error on timeouts (Typhoeus for 
example).


### State stores

By default, Stroombreker uses a per process Hash to store the current state in,
implemented in `Stroombreker::MemoryStateStore`. This will of course not be
usable in a multi thread/process environment. Another StateStore implementation
is included in the form of `Stroombreker::RedisStateStore`. To specify a
store, use the `:state_store` param to `Stroombreker.register`:

````ruby
redis_connection = Redis.connect # or get a redis connection some other way
Stroombreker.register(
  # ... other params
  state_store: Stroombreker::RedisStateStore.new(redis_connection)
)
````

To implement another StateStore (memcached anyone?), there are contract tests
for that in `spec/state_store.rb`. See `spec/memory_state_store_spec.rb` and
`spec/redis_state_store_spec` for examples.

### Status

You can get status for all registered Circuit breakers by calling
`Stroombreker.all`. This returns the actual `CircuitBreaker` objects` objects.

## TODO

Some things should be changed.

- Remove the dependency on activesupport. It was only added because I (Patrik)
  was lazy when writing specs

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
