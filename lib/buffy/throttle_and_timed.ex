# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule Buffy.ThrottleAndTimed do
  @moduledoc """
  This is a variation on the `Buffy.Throttle` behavior.

  It keeps the following functionality:
    - wait for a specified amount of time before
  invoking the work function. If the function is called again before the time has
  elapsed, it's a no-op.

  Key difference between `Buffy.Throttle` and `Buffy.ThrottleAndTimed`:
    - it will not be terminated once the timer is done, but kept alive
      - internally, the existing timer behavior is done via state rather than handling `{:error, {:already_started, pid}}` output of `GenServer.start_link`.
        - See note on Horde about state.
    - it will be given the option (set by config) to trigger work repeatedly based on a empty inbox timeout interval,
      that is based on [GenServer's timeout feature](https://hexdocs.pm/elixir/1.12/GenServer.html#module-timeouts).

  Main reason for these changes is sometimes there's a need to fall back to a time-interval triggered work, when there aren't any triggers to
  start the work. Requirement of this means the process should exist and not get terminated immediately after a successfully throttled work execution.

  ### In other words, we keep the throttle mechanism:

  Once the timer has expired, the function will be called,
  and any subsequent calls will start a new timer.

  ```text
  call     call   call               call           call
   | call   | call | call             | call         |
   |  |     |  |   |  |               |  |           |
  ┌─────────┐  ┌─────────┐            ┌─────────┐    ┌─────────┐
  │ Timer 1 │  │ Timer 2 │            │ Timer 3 │    │ Timer 4 │
  └─────────|  └─────────┘            └─────────┘    └─────────┘
            |            |                      |              |
            |            |                      |    Forth function invocation
            |            |            Third function invocation
            | Second function invocation
  First function invocation
  ```

  ### With the optionally enabled trigger, ending up in this lifecycle:

  ```mermaid
  graph TB
    A[Start Buffy] -->|start_link| B(Init Buffy)
    B --> |initial handle_continue| W(Do throttled work)
    S(Messages sent to Buffy) --> |message to trigger work| D{Can Throttle?}
    D --> |YES| W
    D --> |NO| C(Ignore message as throttle already scheduled)
    S --> |empty inbox timeout interval| P(Do immediate work)
    W --> |set message inbox timeout| S
    P --> |set message inbox timeout| S
  ```

  ### Note on Horde based usage

  Under Horde, the state unfortunately doesn't get synced up automatically - that requires explicit tooling.
  Therefore state will be "reset" to the initial state when process boots up. This is not a big issue as the initial state is to
  set a throttled run of `handle_throttle`.

  ### How to start timed interval triggers when your application boots up

  This will not run when your application starts. The suggested approach is to create a child spec for the application Supervisor (typically in `application.ex`)
  for a Task module, that runs how many instances of `throttle/1` as necessary. That way, the default inbox timeout will run,
  using `loop_interval`, as some variation of:

  ```
  # application.ex
  def start(_type, _args) do
    ...
    children = [
      ...
      {true,
       Supervisor.child_spec(
         {Task,
          fn ->
            for x <- 1..10, do: MyModuleUsingThrottleAndTimed.throttle(some: "value", x: x)
          end},
         id: MyModuleUsingThrottleAndTimedInit,
         restart: :temporary
       )}
    ]
    ...
  ```

  ## Example Usage

  You'll first need to create a module that will be used to throttle.

      defmodule MyTask do
        use Buffy.ThrottleAndTimed,
          throttle: :timer.minutes(2)
          loop_timeout: :timer.minutes(2)

        def handle_throttle(args) do
          # Do something with args
        end
      end

  Next, you can use the `throttle/1` function with the registered module.

      iex> MyTask.throttle(args)
      :ok

  ## Options

    - `:registry_module` (`atom`) - Optional. A module that implements the `Registry` behaviour. If you are running in a distributed instance, you can set this value to `Horde.Registry`. Defaults to `Registry`.

    - `:registry_name` (`atom`) - Optional. The name of the registry to use. Defaults to the built in Buffy registry, but if you are running in a distributed instance you can set this value to a named `Horde.Registry` process. Defaults to `Buffy.Registry`.

    - `:restart` (`:permanent` | `:temporary` | `:transient`) - Optional. The restart strategy to use for the GenServer. Defaults to `:temporary`.

    - `:supervisor_module` (`atom`) - Optional. A module that implements the `DynamicSupervisor` behaviour. If you are running in a distributed instance, you can set this value to `Horde.DynamicSupervisor`. Defaults to `DynamicSupervisor`.

    - `:supervisor_name` (`atom`) - Optional. The name of the dynamic supervisor to use. Defaults to the built in Buffy dynamic supervisor, but if you are running in a distributed instance you can set this value to a named `Horde.DynamicSupervisor` process. Defaults to `Buffy.DynamicSupervisor`.

    - :throttle (`non_neg_integer`) - Required. The amount of time to wait before invoking the function. This value is in milliseconds.

    - `:loop_interval` (`atom`) - Optional. The amount of time that this process will wait while inbox is empty until sending a `:timeout` message (handle via `handle_info`). Resets if message comes in. In milliseconds.

  ## Using with Horde

  If you are running Elixir in a cluster, you can utilize `Horde` to only run one of your throttled functions at a time. To do this, you'll need to set the `:registry_module` and `:supervisor_module` options to `Horde.Registry` and `Horde.DynamicSupervisor` respectively. You'll also need to set the `:registry_name` and `:supervisor_name` options to the name of the Horde registry and dynamic supervisor you want to use.

        defmodule MyThrottler do
          use Buffy.ThrottleAndTimed,
            registry_module: Horde.Registry,
            registry_name: MyApp.HordeRegistry,
            supervisor_module: Horde.DynamicSupervisor,
            supervisor_name: MyApp.HordeDynamicSupervisor,
            throttle: :timer.minutes(2),
            loop_timeout: :timer.minutes(10)

          def handle_throttle(args) do
            # Do something with args
          end
        end

  ## Telemetry

  These are the events that are called by the `Buffy.ThrottleAndTimed` module:

  - `[:buffy, :throttle, :throttle]` - Emitted when the `throttle/1` function is called.
  - `[:buffy, :throttle, :handle, :start]` - Emitted at the start of the `handle_throttle/1` function.
  - `[:buffy, :throttle, :handle, :stop]` - Emitted at the end of the `handle_throttle/1` function.
  - `[:buffy, :throttle, :handle, :exception]` - Emitted when an error is raised in the `handle_throttle/1` function.

  All of these events will have the following metadata:

  - `:args` - The arguments passed to the `throttle/1` function.
  - `:key` - A hash of the passed arguments used to deduplicate the throttled function.
  - `:module` - The module using `Buffy.ThrottleAndTimed`.

  With the additional metadata for `[:buffy, :throttle, :handle, :stop]`:

  - `:result` - The return value of the `handle_throttle/1` function.

  """
  require Logger
  alias Buffy.ThrottleAndTimed

  @typedoc """
  A list of arbitrary arguments that are used for the `c:handle_throttle/1`
  function.
  """
  @type args :: term()

  @typedoc """
  A unique key for debouncing. This is used for GenServer uniqueness and is
  generated from hashing all of the args.
  """
  @type key :: term()

  @typedoc """
  Internal state that `Buffy.Throttle` keeps.
  """
  @type state :: %{
          key: key(),
          args: args(),
          work_status: :in_progress | :scheduled_by_loop_interval | :scheduled | :complete
        }

  @doc """
  A function to call the throttle. This will start
  and wait the configured `throttle` time before calling the `c:handle_throttle/1`
  function.
  """
  @callback throttle(args :: args()) :: :ok | {:error, term()}

  @doc """
  The function called after the throttle has completed. This function will
  receive the arguments passed to the `throttle/1` function.
  """
  @callback handle_throttle(args()) :: any()

  defmacro __using__(opts) do
    registry_module = Keyword.get(opts, :registry_module, Registry)
    registry_name = Keyword.get(opts, :registry_name, Buffy.Registry)
    restart = Keyword.get(opts, :restart, :temporary)
    supervisor_module = Keyword.get(opts, :supervisor_module, DynamicSupervisor)
    supervisor_name = Keyword.get(opts, :supervisor_name, Buffy.DynamicSupervisor)
    throttle = Keyword.fetch!(opts, :throttle)
    loop_interval = Keyword.get(opts, :loop_interval)

    quote do
      @behaviour Buffy.ThrottleAndTimed

      use GenServer, restart: unquote(restart)

      require Logger

      @doc false
      @spec start_link({ThrottleAndTimed.key(), ThrottleAndTimed.args()}) :: :ignore | {:ok, pid} | {:error, term()}
      def start_link({key, args}) do
        name = key_to_name(key)

        with {:error, {:already_started, pid}} <- GenServer.start_link(__MODULE__, {key, args}, name: name) do
          :ignore
        end
      end

      @doc """
      Starts debouncing the given `t:Buffy.ThrottleAndTimed.key()` for the
      module set `throttle` time. Returns a tuple containing `:ok`
      and the `t:pid()` of the throttle process.

      ## Examples

          iex> throttle(:my_function_arg)
          {:ok, #PID<0.123.0>}

      """
      @impl Buffy.ThrottleAndTimed
      @spec throttle(Buffy.Throttle.args()) :: :ok | {:error, term()}
      def throttle(args) do
        key = args_to_key(args)

        :telemetry.execute(
          [:buffy, :throttle, :throttle],
          %{count: 1},
          %{args: args, key: key, module: __MODULE__}
        )

        case unquote(supervisor_module).start_child(unquote(supervisor_name), {__MODULE__, {key, args}}) do
          {:ok, pid} ->
            :ok

          :ignore ->
            # already started; Trigger throttle for that process
            key |> key_to_name |> GenServer.cast(:throttle)

          result ->
            result
        end
      end

      defp args_to_key(args), do: args |> :erlang.term_to_binary() |> :erlang.phash2()

      defp key_to_name(key) do
        {:via, unquote(registry_module), {unquote(registry_name), {__MODULE__, key}}}
      end

      @doc """
      The function that runs after throttle has completed. This function will
      be called with the `t:Buffy.ThrottleAndTimed.key()` and can return anything. The
      return value is ignored. If an error is raised, it will be logged and
      ignored.

      ## Examples

      A simple example of implementing the `c:Buffy.Throttle.handle_throttle/1`
      callback:

          def handle_throttle(args) do
            # Do some work
          end

      Handling errors in the `c:Buffy.Throttle.handle_throttle/1` callback:

          def handle_throttle(args) do
            # Do some work
          rescue
            e ->
              # Do something with a raised error
          end

      """
      @impl Buffy.ThrottleAndTimed
      @spec handle_throttle(Buffy.ThrottleAndTimed.args()) :: any()
      def handle_throttle(_args) do
        raise RuntimeError,
          message: "You must implement the `handle_throttle/1` function in your module."
      end

      defoverridable handle_throttle: 1

      @doc false
      @impl GenServer
      @spec init({ThrottleAndTimed.key(), ThrottleAndTimed.args()}) :: {:ok, Buffy.ThrottleAndTimed.state()}
      def init({key, args}) do
        Process.send_after(self(), :timeout, unquote(throttle))
        {:ok, %{key: key, args: args, work_status: :scheduled}}
      end

      @doc """
      Function to invoke the throttle logic if process already exists.
      It will invoke the throttle logic if `:work_status` in state is either `:complete` or `:scheduled_by_loop_interval`.
      `:scheduled_by_loop_interval` is set by the empty inbox timeout, which should be overruled with any incoming message -
      since the timeout is reset by the definition of empty inbox timeout, the throttle logic can safely be scheduled.

      """
      @impl GenServer
      @spec handle_cast(:throttle, Buffy.ThrottleAndTimed.state()) :: {:noreply, Buffy.ThrottleAndTimed.state()}
      def handle_cast(:throttle, %{work_status: :complete} = state) do
        Process.send_after(self(), :timeout, unquote(throttle))
        {:noreply, %{state | work_status: :scheduled}}
      end

      def handle_cast(:throttle, %{work_status: :scheduled_by_loop_interval} = state) do
        Process.send_after(self(), :timeout, unquote(throttle))
        {:noreply, %{state | work_status: :scheduled}}
      end

      def handle_cast(:throttle, %{work_status: _} = state) do
        {:noreply, state}
      end

      @doc false
      @impl GenServer
      @spec handle_info(:timeout, Buffy.ThrottleAndTimed.state()) ::
              {:noreply, Buffy.ThrottleAndTimed.state(), {:continue, :do_work}}
      def handle_info(:timeout, %{key: key, args: args} = state) do
        new_state = %{state | work_status: :in_progress}
        {:noreply, new_state, {:continue, :do_work}}
      end

      @doc false
      @impl GenServer
      @spec handle_continue(do_work :: atom(), Buffy.ThrottleAndTimed.state()) ::
              {:noreply, Buffy.ThrottleAndTimed.state()} | {:noreply, Buffy.ThrottleAndTimed.state(), timeout()}
      def handle_continue(:do_work, %{key: key, args: args} = state) do
        :telemetry.span(
          [:buffy, :throttle, :handle],
          %{args: args, key: key, module: __MODULE__},
          fn ->
            result = handle_throttle(args)
            {result, %{args: args, key: key, module: __MODULE__, result: result}}
          end
        )

        new_state = %{state | work_status: :complete}
        maybe_add_inbox_timeout_and_update_work_status({:noreply, new_state})
      rescue
        e ->
          Logger.error("Error in throttle: #{inspect(e)}")
          new_state = %{state | work_status: :complete}
          maybe_add_inbox_timeout_and_update_work_status({:noreply, new_state})
      end

      defp maybe_add_inbox_timeout_and_update_work_status(
             {return_signal, %{work_status: work_status} = state} = return_tuple
           ) do
        loop_interval = unquote(loop_interval)

        ThrottleAndTimed.maybe_add_inbox_timeout_and_update_work_status(loop_interval, return_tuple)
      end
    end
  end

  def maybe_add_inbox_timeout_and_update_work_status(nil, return_tuple), do: return_tuple

  def maybe_add_inbox_timeout_and_update_work_status(
        loop_interval,
        {return_signal, %{work_status: work_status} = state} = return_tuple
      )
      when is_number(loop_interval) do
    if work_status == :complete do
      {return_signal, %{state | work_status: :scheduled_by_loop_interval}, loop_interval}
    else
      return_tuple
    end
  end

  def maybe_add_inbox_timeout_and_update_work_status(loop_interval, return_tuple) do
    Logger.error("Error parsing :loop_interval - value is not a number, will ignore. Got: #{inspect(loop_interval)}")

    return_tuple
  end
end
