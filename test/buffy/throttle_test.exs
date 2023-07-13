defmodule Buffy.ThrottleTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(MyZeroThrottler)
    :ok
  end

  # Extend timeout for the 10_000 runs CI does + the Process.sleep call.
  # Because MyZeroDebouncer.debounce/1 is async, we need to sleep to ensure
  # the logic is ran.
  @tag timeout: :timer.minutes(5)
  test "calls handle_debounce/1" do
    check all args <- StreamData.term() do
      assert {:ok, _pid} = MyZeroThrottler.throttle(args)
      Process.sleep(1)
      assert_called MyZeroThrottler.handle_throttle(args)
    end
  end
end
