defmodule MyDebouncer do
  use Buffy.Debounce,
    concurrency: :infinity,
    debounce: 0

  def handle_debounce(_args) do
    :ok
  end
end
