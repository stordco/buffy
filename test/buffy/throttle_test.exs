defmodule Buffy.ThrottleTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(MyZeroThrottler)
    :ok
  end

  # Extend timeout for the number of CI runs + the Process.sleep call.
  # Because MyZeroDebouncer.debounce/1 is async, we need to sleep to ensure
  # the logic is ran.
  @tag timeout: :timer.minutes(10)
  test "calls handle_debounce/1" do
    check all args <- StreamData.term() do
      assert {:ok, _pid} = MyZeroThrottler.throttle(args)
      Process.sleep(1)
      assert_called MyZeroThrottler.handle_throttle(args)
    end
  end

  describe ":telemetry" do
    setup do
      _ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:buffy, :throttle, :throttle],
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
      patch(MyZeroThrottler, :handle_throttle, fn _ -> raise "oops" end)
      MyZeroThrottler.throttle(:exception)

      assert_receive {[:buffy, :throttle, :handle, :exception], _ref, %{duration: _},
                      %{
                        args: :exception,
                        key: _,
                        kind: :error,
                        reason: %RuntimeError{message: "oops"},
                        module: MyZeroThrottler
                      }}
    end
  end
end
