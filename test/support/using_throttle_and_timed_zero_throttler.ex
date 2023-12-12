defmodule UsingThrottleAndTimedZeroThrottler do
  use Buffy.ThrottleAndTimed, throttle: 0

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
