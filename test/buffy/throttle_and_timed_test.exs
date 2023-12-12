defmodule Buffy.ThrottleAndTimedTest do
  use ExUnit.Case, async: true
  use Patch
  use ExUnitProperties

  setup do
    spy(UsingThrottleAndTimedZeroThrottler)
    spy(UsingThrottleAndTimedSlowThrottler)
    :ok
  end

  describe "handle_info(:timeout)" do
    defmodule MyDynamicSupervisor do
      use DynamicSupervisor

      def start_link(init_arg) do
        DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
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

      def handle_throttle(%{test_pid: test_pid} = args) do
        send(test_pid, {:ok, args, System.monotonic_time()})
        :ok
      end
    end

    setup do
      start_supervised!({MyDynamicSupervisor, []})
      :ok
    end

    test "should trigger if no message in inbox for loop_interval" do
      prev = System.monotonic_time()
      DynamicSupervisor.count_children(MyDynamicSupervisor)
      test_pid = self()
      MyTimedThrottler.throttle(%{test_pid: test_pid, prev: prev})
      assert_receive {:ok, %{prev: ^prev}, now}, 200

      # Initial throttle is 10 msec so should receive within 20 msec
      assert System.convert_time_unit(now - prev, :native, :millisecond) < 20

      # Inbox timeout triggers at 100 msec so should receive "around" that time
      assert_receive {:ok, %{prev: ^prev}, now2}, 200
      diff = System.convert_time_unit(now2 - now, :native, :millisecond)
      assert :erlang.abs(diff - 100) < 10

      # Confirm another inbox timeout triggered
      assert_receive {:ok, %{prev: ^prev}, now3}, 200
      diff = System.convert_time_unit(now3 - now2, :native, :millisecond)
      assert :erlang.abs(diff - 100) < 10
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
