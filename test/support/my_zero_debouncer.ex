defmodule MyZeroDebouncer do
  use Buffy.Debounce, debounce: 0

  def handle_debounce(_args) do
    :ok
  end
end
