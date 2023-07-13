defmodule Buffy.DebounceTest do
  use ExUnit.Case, async: true
  use Patch

  setup do
    spy(MyZeroDebouncer)
  end

  test "calls handle_debounce/1" do
    assert :ok = MyZeroDebouncer.debounce({:test_arg})
    Process.sleep(1)
    assert_called_once(MyZeroDebouncer.handle_debounce({:test_arg}))
  end
end
