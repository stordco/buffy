defmodule Buffy.ThrottleAndTimedTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(UsingThrottleAndTimedZeroThrottler)
    spy(UsingThrottleAndTimedSlowThrottler)
    spy(MyTimedThrottler)
    :ok
  end

  describe "handle_info(:timeout)" do
    defp get_test_pid, do: self()

    defmodule MyDynamicSupervisor do
      use DynamicSupervisor

      def start_link(init_arg) do
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
      end

      @impl DynamicSupervisor
      def init(_init_arg) do
        DynamicSupervisor.init(strategy: :one_for_one)
      end
    end

    defmodule MyTimedThrottler do
      use Buffy.ThrottleAndTimed,
        throttle: 10,
        loop_interval: 100,
        supervisor_module: DynamicSupervisor,
        supervisor_name: MyDynamicSupervisor

      def handle_throttle(:raise) do
        raise RuntimeError, message: ":raise"
      end

      def handle_throttle(:error) do
        :error
      end

      def handle_throttle(args) do
        send(get_test_pid(), {:ok, args})
        :ok
      end
    end

    setup do
      start_supervised(MyDynamicSupervisor)
      [args: args]
    end
  end

  # Extend timeout for the number of CI runs + the Process.sleep call.
  # Because MyZeroDebouncer.debounce/1 is async, we need to sleep to ensure
  # the logic is ran.
  @tag timeout: :timer.minutes(10)
  test "calls handle_debounce/1" do
    check all args <- StreamData.term() do
      assert :ok = UsingThrottleAndTimedZeroThrottler.throttle(args)
      Process.sleep(1)
      assert_called UsingThrottleAndTimedZeroThrottler.handle_throttle(args)
    end
  end

  test "throttles handle_debounce/1" do
    for _ <- 1..200, do: UsingThrottleAndTimedSlowThrottler.throttle(:testing)
    Process.sleep(100)
    assert_called_once UsingThrottleAndTimedSlowThrottler.handle_throttle(:testing)
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
      UsingThrottleAndTimedZeroThrottler.throttle(:foo)

      assert_receive {[:buffy, :throttle, :throttle], _ref, %{count: 1},
                      %{
                        args: :foo,
                        key: _,
                        module: UsingThrottleAndTimedZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :start]" do
      UsingThrottleAndTimedZeroThrottler.throttle(:starting)

      assert_receive {[:buffy, :throttle, :handle, :start], _ref, %{},
                      %{
                        args: :starting,
                        key: _,
                        module: UsingThrottleAndTimedZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :stop]" do
      UsingThrottleAndTimedZeroThrottler.throttle(:stopping)

      assert_receive {[:buffy, :throttle, :handle, :stop], _ref, %{duration: _},
                      %{
                        args: :stopping,
                        key: _,
                        result: :ok,
                        module: UsingThrottleAndTimedZeroThrottler
                      }}
    end

    test "emits [:buffy, :throttle, :handle, :exception]" do
      UsingThrottleAndTimedZeroThrottler.throttle(:raise)

      assert_receive {[:buffy, :throttle, :handle, :exception], _ref, %{duration: _},
                      %{
                        args: :raise,
                        key: _,
                        kind: :error,
                        reason: %RuntimeError{message: ":raise"},
                        module: UsingThrottleAndTimedZeroThrottler
                      }}
    end
  end
end
