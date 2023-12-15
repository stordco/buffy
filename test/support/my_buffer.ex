defmodule MyBuffer do
  use Buffy.Buffer, throttle: 100

  def handle_buffer(:raise) do
    raise RuntimeError, message: ":raise"
  end

  def handle_buffer(:error) do
    :error
  end

  def handle_throttle(_args) do
    :ok
  end
end
