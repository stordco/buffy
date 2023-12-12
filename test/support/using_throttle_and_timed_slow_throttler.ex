defmodule UsingThrottleAndTimedSlowThrottler do
  use Buffy.ThrottleAndTimed, throttle: 100

  def handle_throttle(:raise) do
    raise RuntimeError, message: ":raise"
  end

  def handle_throttle(:error) do
    :error
  end

  def handle_throttle(_args) do
    :ok
  end
end
