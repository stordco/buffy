defmodule Buffy.DebounceTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(MyZeroDebouncer)
    :ok
  end

  # Extend timeout for the 10_000 runs CI does + the Process.sleep call.
  # Because MyZeroDebouncer.debounce/1 is async, we need to sleep to ensure
  # the logic is ran.
  @tag timeout: :timer.minutes(2)
  test "calls handle_debounce/1" do
    check all args <- StreamData.term() do
      assert :ok = MyZeroDebouncer.debounce(args)
      Process.sleep(1)
      assert_called MyZeroDebouncer.handle_debounce(args)
    end
  end
end
