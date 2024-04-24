# ⚡️ Next

Next is an actor model framework for Ruby, designed to simplify concurrent programming.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add next

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install next

## What is the Actor Model?

The Actor Model is a programming paradigm that treats "actors" as the universal primitive for concurrent computation. 
You can think of an actor as an individual unit of computation that encapsulates both state and behavior. Unlike 
traditional object-oriented programming, where objects communicate by invoking methods on each other, actors communicate 
exclusively through asynchronous message passing.

In the Actor Model, each actor has its own unique identity and maintains its own internal state. Actors can send 
messages to each other, and upon receiving a message, an actor can perform various actions such as updating its state, 
sending messages to other actors, or creating new actors. Crucially, actors operate independently and concurrently, 
allowing for efficient and scalable concurrent programming without the need for locks or explicit synchronization 
mechanisms.

The Actor Model provides a high-level abstraction for building concurrent and distributed systems, making it easier to 
reason about and manage complex interactions between concurrent entities. By isolating state and enforcing message 
passing, the Actor Model promotes a more resilient and fault-tolerant approach to concurrent programming.

## Usage

Actors does not live on their own, they need an Actor System to be created first:

```ruby
actor_system = Next.system("example")
```

### Creating Actors

Actors are implemented by inheriting from the `Next::Actor` class and implementing the `#receive` method. 
The `#receive` method may either process or ignore a message received as an argument.

Here is an example:

```ruby 
class Counter < Next::Actor
  def initialize(initial:)
    @counter = initial
  end

  def receive(message)
    case message
    in ['+', value]
      @counter += value
    in ['-', value] 
      @counter -= value
    in 'counter'
      sender << @counter
    end
  end
end
```

Please note that you need to explicitly handle all the incoming messages; otherwise, any unknown message will be silently ignored.

`Next::Actor#receive` is considered an actor's "initial behavior". See [Become/Unbecome][] for further information on 
changing the behavior of an actor after its construction.

#### Props

`Next::Props` represents the configuration of actors. They are immutable and may be freely shared between actors.

```ruby
props1 = Next.props(MyActor)
props2 = Next.props(Counter, initial: 42)
```

Actors (and thus, their props) allow only keyword arguments. The last example shows how to pass `initial: 42` to the actor's initializer.

##### Creating Actors with Props

Actors are created by passing an instance of `Props` into the `System#actor_of` method.

```ruby
counter_props = Next.props(Counter, initial: 42)
counter = actor_system.actor_of(counter_props, "my-actor")
```

### Sending Messages

Once actors are created, you can send messages to them using the `<<` operator:

```ruby
counter << ['+', 5]  # Increment counter by 5
counter.tell ['-', 3]  # Decrement counter by 3
counter.tell 'counter' # Request current counter value
```

In the above example, messages are sent to the `counter` actor to perform operations or request its current state.

Additionally, actors support request/response style communication using the `ask` and `ask!` methods:

`ask`: Sends a message to an actor and returns a `Fear::Future` representing the response.
`ask!`: Sends a message to an actor and returns a `Fear::Option` representing the response, with an optional timeout parameter.

```ruby
future = counter.ask('counter') # Send message and get a Future representing the response
option = counter.ask!('counter') # Send message and get an Option representing the response
```

In the above examples, `ask` and `ask!` are used to send messages and retrieve responses from the counter actor.

```ruby
class OtherActor < Next::Actor
  def initialize(counter)
    @counter = counter
  end

  def receive(message)
    case message
    in 'request'
      @counter << 'counter' # Request the current counter value
    in Integer(value)
      puts "The value is #{value}"
    end
  end
end
```

In this example, the `OtherActor` sends a message to the `Counter` actor to request its current value 
asynchronously and then processes the response.

### Errors handling and Supervision

Supervision in the Next framework provides a mechanism for managing the behavior of child actors in response to failures. 
When a child actor encounters an exception during execution, it suspends its operation and notifies its parent about 
the failure. The parent actor then decides how to handle the error and communicates its decision back to the child. 
There are several options available for handling failures:

1. **Resume**: The parent instructs the child to continue its execution, maintaining its current state.
2. **Restart**: The parent restarts the child actor, discarding any accumulated state.
3. **Stop**: The parent stops the child actor altogether, ceasing its execution.
4. **Escalate**: The parent defers the decision to handle the error to its own parent.

There are two primary supervision strategies: "One for One" and "All for One."

* With "One for One" supervision, the parent applies the supervision strategy only to the failing child.
* With "All for One" supervision, the parent applies the supervision strategy to all its children, not just the failing one.

Here's an example of implementing a supervision strategy:

```ruby
class ParentActor < Next::Actor
  def initialize
    @child_props = Next.props(ChildActor)
  end

  def receive(message)
    case message
    in 'spawn_child'
      # Spawn a child actor using the provided props
      @child_actor = context.actor_of(@child_props)
    end
  end

  def supervision_strategy
    Next::OneForOneStrategy.new do |error|
      case error
      in ZeroDivisionError
        Next::SupervisorStrategy::RESTART # Restart child on division by zero error
      else 
        Next::SupervisorStrategy::ESCALATE # Escalate all other errors to the parent
      end
    end
  end
end
```

When an actor spawns another one using the `context.actor_of` API, it automatically becomes its parent and 
therefore its supervisor.

In this example, we define a custom supervision strategy using a `Next::OneForOneStrategy`. The block takes an 
exception as an argument and returns a symbol instructing Next on how to handle the error. In case a nil or 
`NoMatchingPatternError` is raised, the default decision is applied, which is `Next::SupervisorStrategy::ESCALATE`.

By default, Next uses the "One for One" supervision strategy, which restarts a failing child actor. To use the 
"All for One" strategy, you can utilize `Next::AllForOneStrategy` instead of `Next::OneForOneStrategy`.

### Shutting Down the Actor System

Shutting down an actor system gracefully is essential for ensuring proper resource cleanup and preventing data loss. 
In the Next framework, terminating an actor system involves stopping all actors within the system in an orderly manner.
During the actor system shutdown, all the necessary actor callbacks are executed.

To shut down an actor system, you have two main methods available: `terminate` and `terminate!`.

The `terminate` method initiates the shutdown process by stopping the root actor of the system, which triggers 
the stopping of all its children (which include user-defined actors). The method does not wait for 
the termination to complete and returns an unresolved `Fear::Future` of `Next::Terminated` immediately.

```ruby
# Gracefully terminate the actor system
actor_system.terminate
```

The `terminate!` method also initiates the shutdown process by stopping the root actor of the system, but it blocks 
the current thread until the termination is complete. This ensures that the termination is fully processed 
before continuing.

```ruby
# Gracefully terminate the actor system, blocking until termination is finished
actor_system.terminate!
```

If you need to block the current thread until the actor system is terminated, you can use the `await_termination` 
method. This method waits until the termination future resolves and returns the result. It's important to note that 
this method does not trigger termination; it simply prevents the application from exiting while the actor system 
is still running.

```ruby
# Create an actor system
actor_system = Next.system("example")

# Block until the actor system is fully terminated
actor_system.await_termination
```

## Handling Interrupt Signals

When the application is terminated, Next can handle graceful shutdown by default. However, if a user wants to 
**override** this signal handler, they need to call the `Next::System#terminate_all!` method manually. This method ensures 
that all known actor systems are properly terminated even when an interrupt signal (SIGINT) is received.

Example:
```ruby
Signal.trap("INT") {
  Next::System.terminate_all!
  # user defined code
  exit
}
```

This signal handler ensures that all actor systems are terminated when the user presses Ctrl+C or sends an 
interrupt signal to the application.

### Testing

`Next` comes with RSpec support. To activate it, include `rext/testing/rspec` and use the `:actor_system` shared context.

```ruby 
require "next/testing/rspec"

RSpec.describe MyActor, :actor_system do 
end 
```

Under the hood, we run `test_actor` that logs all the received messages. There is a set of matchers for inspecting those messages.

```ruby
class EchoActor < Next::Actor

  def receive(message)
    sender.tell(message)
  end
end

RSpec.describe EchoActor, :actor_system do    
  it "sends back messages unchanged" do
    echo = system.actor_of(EchoActor)
    echo.tell("How are you?")

    expect_message("How are you?")
  end 
end
```

#### Matchers

The `expect_message` matcher expects exactly the given message.

```ruby 
test_actor.tell "How are you?"

expect_message("How are you?") # passes
expect_message("Bye") # fails
```

It's worth mentioning that you can use RSpec matchers for your expectations:

```ruby 
test_actor.tell "How are you?"

expect_message(be_kind_of(String)) # passes
expect_message(be_kind_of(Integer)) # fails
```

Use `expect_no_message` to expect no message within the default timeout of 3 seconds:

 ```ruby 
test_actor.tell "How are you?"

expect_no_message("Bye") # passes

Thread.new do 
  test_actor.tell "How are you?"
  sleep 0.1
  test_actor.tell "Bye"
end

expect_no_message("Bye", timeout: 0.3) # fails with 'received unexpected message "Hi! How are you?" after 102 millis'
```

The `fish_for_message` method waits for a specific message from an actor, ensuring that the expected message is 
received within a given timeout period (3 seconds by default).

```ruby
RSpec.describe EchoActor, :actor_system do    
  it "waits for a specific message" do
    echo = system.actor_of(EchoActor)
    echo.tell("Hello!")

    received_message = fish_for_message("Hello!", timeout: 10)
    expect(received_message).to eq("Hello!") 
  end 
end
```

In the above examples, `fish_for_message` is used to wait for a specific message from an actor. All non-matching messages
are ignored.

The `await_condition` method waits until a condition is met within a given timeout period.

```ruby
RSpec.describe WaitActor, :actor_system do    
  it "waits for a condition to be met" do
    wait = system.actor_of(WaitActor)
    wait.tell(:start)

    await_condition(timeout: 10, message: "The actor was not started within 10 secs") do
      wait.ask!(:started?).include?(true)
    end
  end 
end
```

The `await_condition` is used to wait until a condition is met. If the condition is not met within the specified timeout
, an expectation fails.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run 
the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a 
new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which 
will create a git tag for the version, push git commits and the created tag, and push the `.gem` file 
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bolshakov/next.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
