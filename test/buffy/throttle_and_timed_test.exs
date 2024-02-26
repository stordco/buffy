defmodule Buffy.ThrottleAndTimedTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import ExUnit.CaptureLog

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

  defmodule MySlowThrottler do
    use Buffy.ThrottleAndTimed,
      throttle: 100,
      supervisor_module: DynamicSupervisor,
      supervisor_name: MyDynamicSupervisor,
      loop_interval: 200

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

  defmodule MyZeroThrottler do
    use Buffy.ThrottleAndTimed,
      throttle: 0,
      supervisor_module: DynamicSupervisor,
      supervisor_name: MyDynamicSupervisor,
      loop_interval: 100

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

  describe "handle_info(:timeout)" do
    defmodule MyTimedThrottler do
      use Buffy.ThrottleAndTimed,
        throttle: 10,
        loop_interval: 100,
        supervisor_module: DynamicSupervisor,
        supervisor_name: MyDynamicSupervisor

      def handle_throttle(%{test_pid: test_pid} = args) do
        send(test_pid, {:ok, args, System.monotonic_time()})
        :ok
      end
    end

    defmodule MyTimedSlowThrottler do
      use Buffy.ThrottleAndTimed,
        throttle: 100,
        loop_interval: 300,
        supervisor_module: DynamicSupervisor,
        supervisor_name: MyDynamicSupervisor

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
      test_pid = self()
      MyTimedThrottler.throttle(%{test_pid: test_pid, prev: prev})

      # Initial throttle is 10 msec so should receive within 20 msec
      assert_receive {:ok, %{prev: ^prev}, now}, 200
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

    test "should throttle all incoming triggers when work is already scheduled" do
      test_pid = self()
      # trigger throttle
      MyTimedSlowThrottler.throttle(%{test_pid: test_pid})

      # trigger more throttle
      for _ <- 1..10 do
        Task.async(fn ->
          MyTimedSlowThrottler.throttle(%{test_pid: test_pid})
        end)
      end

      # assert throttled work done
      assert_receive {:ok, _, now}, 200

      # refute any other work was done
      refute_receive {:ok, _, _now}, 200

      # check inbox timeout triggered
      assert_receive {:ok, _, now2}, 400
      diff = System.convert_time_unit(now2 - now, :native, :millisecond)
      assert :erlang.abs(diff - 300) < 10
    end

    test "should reset inbox timeout if throttle request comes in" do
      test_pid = self()
      # trigger initial throttle
      MyTimedSlowThrottler.throttle(%{test_pid: test_pid})

      # assert throttled work done
      assert_receive {:ok, _, now}, 200

      # now in inbox timeout waiting period and work scheduled via inbox timeout logic
      # trigger a throttle
      MyTimedSlowThrottler.throttle(%{test_pid: test_pid})

      # assert the trigger happend within the throttle interval and not the inbox timeout loop interval
      assert_receive {:ok, _, now2}, 400
      diff = System.convert_time_unit(now2 - now, :native, :millisecond)
      assert :erlang.abs(diff - 100) < 10
    end
  end

  describe "handle_throttle/1" do
    setup do
      start_supervised!({MyDynamicSupervisor, []})
      :ok
    end

    test "calls handle_throttle/1" do
      check all args <- StreamData.term() do
        assert :ok = MyZeroThrottler.throttle(%{args: args, test_pid: self()})
        assert_receive {:ok, _, _}
      end
    end

    test "throttles handle_throttle/1" do
      test_pid = self()
      for _ <- 1..200, do: MySlowThrottler.throttle(%{test_pid: test_pid})
      assert_receive {:ok, _, _}, 200
      refute_receive {:ok, _, _}, 200
    end
  end

  describe "usage: collecting args to state and running them when :timeout" do
    defmodule MyTimedSlowBucketingThrottler do
      @moduledoc """
      `args` is a map. It will always come in with %{key: "key"}.
      """
      use Buffy.ThrottleAndTimed,
        throttle: 100,
        supervisor_module: DynamicSupervisor,
        supervisor_name: MyDynamicSupervisor

      def handle_throttle(%{test_pid: test_pid, values: values} = args) do
        Process.sleep(200)
        send(test_pid, {:ok, args, System.monotonic_time()})
        values
      end

      def args_to_key(%{key: key}), do: key |> :erlang.term_to_binary() |> :erlang.phash2()

      def update_args(%{values: values} = old_arg, %{values: new_values} = _new_arg)
          when is_list(values) and is_list(new_values) do
        %{old_arg | values: Enum.sort(values ++ new_values)}
      end

      def update_state_with_work_result(%{args: %{values: state_values} = args} = state, result) do
        pending_values =
          state_values
          |> MapSet.new()
          |> MapSet.difference(MapSet.new(result))
          |> MapSet.to_list()

        %{state | args: %{args | values: pending_values}}
      end
    end

    setup do
      start_supervised!({MyDynamicSupervisor, []})
      :ok
    end

    test "should use overrideable functions to use collection of arg values from all of triggers when work is done" do
      test_pid = self()
      # trigger throttle
      MyTimedSlowBucketingThrottler.throttle(%{key: "my_key", test_pid: test_pid, values: [0]})
      pause_in_middle = 150
      # trigger more throttle
      for x <- 1..10 do
        Task.async(fn ->
          MyTimedSlowBucketingThrottler.throttle(%{key: "my_key", test_pid: test_pid, values: [x]})
        end)

        if x == 2 do
          # wait to trigger handle_throttle() before next set of integers
          Process.sleep(pause_in_middle)
        end
      end

      expected_value = [0, 1, 2]
      assert_receive {:ok, %{values: ^expected_value}, handle_throttle_t1}, 350

      expected_value = [3, 4, 5, 6, 7, 8, 9, 10]
      assert_receive {:ok, %{values: ^expected_value}, handle_throttle_t2}, 350

      diff = System.convert_time_unit(handle_throttle_t2 - handle_throttle_t1, :native, :millisecond)
      assert :erlang.abs(diff - 300) < 10

      # refute no time interval fired as :loop_interval is not set
      refute_receive {:ok, _, _}, 400
    end
  end

  describe ":telemetry" do
    setup do
      :telemetry_test.attach_event_handlers(self(), [
        [:buffy, :throttle, :throttle],
        [:buffy, :throttle, :timeout],
        [:buffy, :throttle, :handle, :start],
        [:buffy, :throttle, :handle, :stop],
        [:buffy, :throttle, :handle, :exception]
      ])

      start_supervised!({MyDynamicSupervisor, []})

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

    test "emits [:buffy, :throttle, :timeout]" do
      args = %{test_pid: self()}
      MyZeroThrottler.throttle(args)

      assert_receive {[:buffy, :throttle, :timeout], _ref, %{count: 1},
                      %{
                        args: ^args,
                        key: _,
                        module: MyZeroThrottler
                      }},
                     150
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

    test "emits [:buffy, :throttle, :handle, :exception]" do
      MyZeroThrottler.throttle(:raise)

      assert capture_log(fn ->
               assert_receive {[:buffy, :throttle, :handle, :exception], _ref, %{duration: _},
                               %{
                                 args: :raise,
                                 key: _,
                                 kind: :error,
                                 reason: %RuntimeError{message: ":raise"},
                                 module: MyZeroThrottler
                               }}
             end)
    end
  end
end
