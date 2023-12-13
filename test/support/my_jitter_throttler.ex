defmodule MyJitterThrottler do
  use Buffy.Throttle,
    jitter: 100,
    throttle: 0

  def handle_throttle(_args) do
    :ok
  end
end
