**Concurrent routines for Ruby.**

Goru is an experimental concurrency library for Ruby.

* **Lightweight:** Goru routines are not backed by fibers or threads. Each routine creates only ~345 bytes of memory overhead.
* **Explicit:** Goru requires you to describe exactly how a routine behaves. Less magic makes for fewer bugs when writing concurrent programs.

Goru was intended for low-level programs like http servers and not for direct use in user-facing code.

## How It Works

Routines are defined with initial state and a block that does work and (optionally) updates the state of the routine:

```ruby
3.times do
  Goru::Scheduler.go(:running) { |routine|
    case routine.state
    when :running
      routine.update(:sleeping)
      routine.sleep(rand)
    when :sleeping
      puts "[#{object_id}] woke up at #{Time.now.to_f}"
      routine.update(:running)
    end
  }
end
```

Routines run concurrently within a reactor, each reactor running in a dedicated thread. Each eligible routine is called
once on every tick of the reactor it is scheduled to run in. In the example above, the three routines sleep for a random
interval before waking up and printing the current time. Here is some example output:

```
[1840] woke up at 1677939216.379147
[1860] woke up at 1677939217.059535
[1920] woke up at 1677939217.190349
[1860] woke up at 1677939217.6196458
[1920] woke up at 1677939217.935916
[1840] woke up at 1677939218.033243
[1860] woke up at 1677939218.532908
[1920] woke up at 1677939218.8669178
[1840] woke up at 1677939219.379714
[1860] woke up at 1677939219.522777
[1920] woke up at 1677939220.0475688
[1840] woke up at 1677939220.253979
```

Each reactor can only run one routine at any given point in time, but if a routine blocks (e.g. by sleeping or
performing i/o) the reactor calls another eligible routine before returning to the previously blocked routine
on the next tick.

## Scheduler

By default Goru routines are scheduled in a global scheduler that waits at the end of the program for all routines
to finish. While this is useful for small scripts, most use-cases will involve creating your own scheduler and
registering routines directly:

```ruby
scheduler = Goru::Scheduler.new
scheduler.go { |routine|
  ...
}
scheduler.wait
```

Routines are scheduled to run immediately after registration.

### Tuning

Schedulers default to running a number of reactors matching the number of processors on the current system. Tune
this to your needs with the `count` option when creating a scheduler:

```ruby
scheduler = Goru::Scheduler.new(count: 3)
```

## State

Routines are initialized with default state that is useful for coordination between ticks. This is perhaps the
oddest part of Goru but the explicitness can make it easier to understand exactly how your routines will behave.

Take a look at the [examples](./examples) to get some ideas.

## Finishing

Routines will run forever until you say they are finished:

```ruby
Goru::Scheduler.go { |routine|
  routine.finished
}
```

### Results

When finishing a routine you can provide a final result:

```ruby
routines = []
scheduler = Goru::Scheduler.new
routines << scheduler.go { |routine| routine.finished(true) }
routines << scheduler.go { |routine| routine.finished(false) }
routines << scheduler.go { |routine| routine.finished(true) }
scheduler.wait

pp routines.map(&:result)
# [true, false, true]
```

## Error Handling

Unhandled errors within a routine cause the routine to enter an `:errored` state. Calling `result` on an errored
routine causes the error to be re-raised. Routines can handle errors elegantly using the `handle` method:

```ruby
Goru::Scheduler.go { |routine|
  routine.handle(StandardError) do |event:|
    # do something with `event`
  end

  ...
}
```

## Sleeping

Goru implements a non-blocking version of `sleep` that makes the routine ineligible to be called until the sleep time
has elapsed. It is important to note that Ruby's built-in sleep method will block the reactor and should not be used.

```ruby
Goru::Scheduler.go { |routine|
  routine.sleep(3)
}
```

Unlike `Kernel#sleep` Goru's sleep method requires a duration.

## Channels

Goru offers buffered reading and writing through channels:

```ruby
channel = Goru::Channel.new

Goru::Scheduler.go(channel: channel, intent: :w) { |routine|
  routine << SecureRandom.hex
}

# This routine is not invoked unless the channel contains data for reading.
#
Goru::Scheduler.go(channel: channel, intent: :r) { |routine|
  value = routine.read
}
```

Channels are unbounded by default, meaning they can hold an unlimited amount of data. This behavior can be changed by
initializing a channel with a specific size. Routines with the intent to write will not be invoked unless the channel
has space available for writing.

```ruby
channel = Goru::Channel.new(size: 3)

# This routine is not invoked if the channel is full.
#
Goru::Scheduler.go(channel: channel, intent: :w) { |routine|
  routine << SecureRandom.hex
}
```

## IO

Goru includes a pattern for non-blocking io. With it you can implement non-blocking servers, clients, etc.

Routines that involve io must be created with an io object and an intent. Possible intents include:

* `:r` for reading
* `:r` for writing
* `:rw` for reading and writing

Here is the beginning of an http server in Goru:

```ruby
Goru::Scheduler.go(io: TCPServer.new("localhost", 4242), intent: :r) { |server_routine|
  next unless client = server_routine.accept

  Goru::Scheduler.go(io: client, intent: :r) { |client_routine|
    next unless data = client_routine.read(16384)

    # do something with `data`
  }
}
```

### Changing Intents

Intents can be changed after a routine is created, e.g. to switch a routine from reading to writing:

```ruby
Goru::Scheduler.go(io: io, intent: :r) { |routine|
  routine.intent = :w
}
```

## Bridges

Goru supports coordinates buffered io using bridges:

```ruby
writer = Goru::Channel.new

Goru::Scheduler.go(io: io, intent: :w) { |routine|
  routine.bridge(writer, intent: :w)
}

Goru::Scheduler.go(channel: writer) { |routine|
  routine << SecureRandom.hex
}
```

This allows routines to easily write data to a buffer independently of how the data is written to io.

## Credits

Goru was designed while writing a project in Go and imagining what Go-like concurrency might look like in Ruby.
