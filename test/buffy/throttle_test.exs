defmodule Buffy.ThrottleTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(MySlowThrottler)
    spy(MyZeroThrottler)
    :ok
  end

  # Extend timeout for the number of CI runs + the Process.sleep call.
  # Because MyZeroDebouncer.debounce/1 is async, we need to sleep to ensure
  # the logic is ran.
  @tag timeout: :timer.minutes(10)
  test "calls handle_debounce/1" do
    check all args <- StreamData.term() do
      assert :ok = MyZeroThrottler.throttle(args)
      Process.sleep(1)
      assert_called MyZeroThrottler.handle_throttle(args)
    end
  end

  test "throttles handle_debounce/1" do
    for _ <- 1..200, do: MySlowThrottler.throttle(:testing)
    Process.sleep(100)
    assert_called_once MySlowThrottler.handle_throttle(:testing)
  end

  describe ":telemetry" do
    setup do
      _ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:buffy, :throttle, :throttle],
          [:buffy, :throttle, :handle, :jitter],
          [:buffy, :throttle, :handle, :start],
          [:buffy, :throttle, :handle, :stop],
          [:buffy, :throttle, :handle, :exception]
        ])

      :ok
    end

    test "emits [:buffy, :throttle, :throttle]" do
      MyZeroThrottler.throttle(:foo)

      assert_receive {[:buffy, :throttle, :throttle], _ref, %{count: 1},
                      %{
                        args: :foo,
                        key: _,
                        module: MyZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :jitter]" do
      MyJitterThrottler.throttle(:foo)

      assert_receive {[:buffy, :throttle, :handle, :jitter], _ref, measurements,
                      %{
                        args: :foo,
                        key: _,
                        module: MyJitterThrottler
                      }}

      assert measurements.jitter >= 0
    end

    test "emits [:buffy, :throttle, :handle, :start]" do
      MyZeroThrottler.throttle(:starting)

      assert_receive {[:buffy, :throttle, :handle, :start], _ref, %{},
                      %{
                        args: :starting,
                        key: _,
                        module: MyZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :stop]" do
      MyZeroThrottler.throttle(:stopping)

      assert_receive {[:buffy, :throttle, :handle, :stop], _ref, %{duration: _},
                      %{
                        args: :stopping,
                        key: _,
                        result: :ok,
                        module: MyZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :exception]" do
      MyZeroThrottler.throttle(:raise)

      assert_receive {[:buffy, :throttle, :handle, :exception], _ref, %{duration: _},
                      %{
                        args: :raise,
                        key: _,
                        kind: :error,
                        reason: %RuntimeError{message: ":raise"},
                        module: MyZeroThrottler
                      }}
    end
  end
end
