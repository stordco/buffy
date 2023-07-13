defmodule Buffy do
  @moduledoc """
  Buffy is broken down into different modules depending on how you want to
  handle your function calling.

  ## Throttle

  The `Buffy.Throttle` module will wait for a specified amount of time before
  invoking the function. If the function is called again before the time has
  elapsed, it's a no-op. Once the timer has expired, the function will be called,
  and any subsequent calls will start a new timer.

  ```text
  call     call   call               call           call
   | call   | call | call             | call         |
   |  |     |  |   |  |               |  |           |
  ┌─────────┐  ┌─────────┐            ┌─────────┐    ┌─────────┐
  │ Timer 1 │  │ Timer 2 │            │ Timer 3 │    │ Timer 4 │
  └─────────|  └─────────┘            └─────────┘    └─────────┘
            |            |                      |              |
            |            |                      |    Forth function invocation
            |            |            Third function invocation
            | Second function invocation
  First function invocation
  ```
  """
end
