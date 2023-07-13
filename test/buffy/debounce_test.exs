defmodule Buffy.DebounceTest do
  use ExUnit.Case, async: true
  use Patch

  setup do
    start_supervised!(MyDebouncer)
    spy(MyDebouncer)
  end

  test "calls handle_apply/1" do
    assert :ok = MyDebouncer.debounce({:test_arg})
    Process.sleep(1)
    assert_called_once(MyDebouncer.handle_debounce({:test_arg}))
  end
end
