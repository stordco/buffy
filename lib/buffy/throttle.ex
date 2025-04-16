# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule Buffy.Throttle do
  @moduledoc """
  The `Buffy.Throttle` module will wait for a specified amount of time before
  invoking the function. If the function is called again before the time has
  elapsed, it's a no-op. Once the timer has expired, the function will be called,
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

  ## Example Usage

  You'll first need to create a module that will be used to throttle.

      defmodule MyTask do
        use Buffy.Throttle,
          throttle: :timer.minutes(2)

        def handle_throttle(args) do
          # Do something with args
        end
      end

  Next, you can use the `throttle/1` function with the registered module.

      iex> MyTask.throttle(args)
      :ok

  ## Options

    - `:jitter` (`integer`) - Optional. The amount of jitter or randomosity to add to the throttle function handle. This value is in milliseconds. Defaults to `0`.

    - `:registry_module` (`atom`) - Optional. A module that implements the `Registry` behaviour. If you are running in a distributed instance, you can set this value to `Horde.Registry`. Defaults to `Registry`.

    - `:registry_name` (`atom`) - Optional. The name of the registry to use. Defaults to the built in Buffy registry, but if you are running in a distributed instance you can set this value to a named `Horde.Registry` process. Defaults to `Buffy.Registry`.

    - `:restart` (`:permanent` | `:temporary` | `:transient`) - Optional. The restart strategy to use for the GenServer. Defaults to `:temporary`.

    - `:supervisor_module` (`atom`) - Optional. A module that implements the `DynamicSupervisor` behaviour. If you are running in a distributed instance, you can set this value to `Horde.DynamicSupervisor`. Defaults to `DynamicSupervisor`.

    - `:supervisor_name` (`atom`) - Optional. The name of the dynamic supervisor to use. Defaults to the built in Buffy dynamic supervisor, but if you are running in a distributed instance you can set this value to a named `Horde.DynamicSupervisor` process. Defaults to `Buffy.DynamicSupervisor`.

    - `:throttle` (`non_neg_integer`) - Optional. The minimum amount of time to wait before invoking the function. This value is in milliseconds. The actual run time could be longer than this value based on the `:jitter` option.

  ### Dynamic Options

  Sometimes you want a different throttle value or jitter value based on the arguments you pass in. To deal with this, there are optional functions you can implement in your throttle module. These functions take in the arguments and will return the throttle and jitter values. For example:

      defmodule MyThrottler do
        use Buffy.Throttle,
          registry_module: Horde.Registry,
          registry_name: MyApp.HordeRegistry,
          supervisor_module: Horde.DynamicSupervisor,
          supervisor_name: MyApp.HordeDynamicSupervisor,
          throttle: :timer.minutes(2)

        def get_jitter(args) do
          case args do
            %Cat{} -> :timer.minutes(2)
            %Dog{} -> :timer.seconds(10)
            _ -> 0
          end
        end
      end

  ## Using with Horde

  If you are running Elixir in a cluster, you can utilize `Horde` to only run one of your throttled functions at a time. To do this, you'll need to set the `:registry_module` and `:supervisor_module` options to `Horde.Registry` and `Horde.DynamicSupervisor` respectively. You'll also need to set the `:registry_name` and `:supervisor_name` options to the name of the Horde registry and dynamic supervisor you want to use.

        defmodule MyThrottler do
          use Buffy.Throttle,
            registry_module: Horde.Registry,
            registry_name: MyApp.HordeRegistry,
            supervisor_module: Horde.DynamicSupervisor,
            supervisor_name: MyApp.HordeDynamicSupervisor,
            throttle: :timer.minutes(2)

          def handle_throttle(args) do
            # Do something with args
          end
        end

  ## Telemetry

  These are the events that are called by the `Buffy.Throttle` module:

  - `[:buffy, :throttle, :throttle]` - Emitted when the `throttle/1` function is called.
  - `[:buffy, :throttle, :handle, :jitter]` - Emitted before the `handle_throttle/1` function is called with the amount of jitter added to the throttle.
  - `[:buffy, :throttle, :handle, :start]` - Emitted at the start of the `handle_throttle/1` function.
  - `[:buffy, :throttle, :handle, :stop]` - Emitted at the end of the `handle_throttle/1` function.
  - `[:buffy, :throttle, :handle, :exception]` - Emitted when an error is raised in the `handle_throttle/1` function.

  All of these events will have the following metadata:

  - `:args` - The arguments passed to the `throttle/1` function.
  - `:key` - A hash of the passed arguments used to deduplicate the throttled function.
  - `:module` - The module using `Buffy.Throttle`.

  With the additional metadata for `[:buffy, :throttle, :handle, :stop]`:

  - `:result` - The return value of the `handle_throttle/1` function.

  ### Memory Leaks

  With any sort of debounce and Elixir processes, you need to be careful about handling too many processes, or having to much state in memory at the same time. If you handle large amounts of data there is a good chance you'll end up with high memory usage and possibly affect other parts of your system.

  To help monitor this usage, Buffy has a telemetry metric that measures the Elixir process memory usage. If you summarize this metric you should get a good view into your buffy throttle processes.

      summary("buffy.throttle.total_heap_size", tags: [:module])

  """

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
  @type state :: {key(), args()}

  @doc """
  A function to call the throttle. This will start
  and wait the configured `throttle` time before calling the `c:handle_throttle/1`
  function.
  """
  @callback throttle(args()) :: :ok | {:error, term()}

  @doc """
  Returns the amount of jitter in milliseconds to add to the throttle time.
  """
  @callback get_jitter(args()) :: non_neg_integer()

  @doc """
  Returns the amount of throttle time in milliseconds.
  """
  @callback get_throttle(args()) :: non_neg_integer()

  @doc """
  The function called after the throttle has completed. This function will
  receive the arguments passed to the `throttle/1` function.
  """
  @callback handle_throttle(args()) :: any()

  defmacro __using__(opts) do
    jitter = Keyword.get(opts, :jitter, 0)
    registry_module = Keyword.get(opts, :registry_module, Registry)
    registry_name = Keyword.get(opts, :registry_name, Buffy.Registry)
    restart = Keyword.get(opts, :restart, :temporary)
    supervisor_module = Keyword.get(opts, :supervisor_module, DynamicSupervisor)
    supervisor_name = Keyword.get(opts, :supervisor_name, Buffy.DynamicSupervisor)
    throttle = Keyword.get(opts, :throttle, 0)

    quote do
      @behaviour Buffy.Throttle

      use GenServer, restart: unquote(restart)

      require Logger

      @doc false
      @spec start_link(Buffy.Throttle.state()) :: {:ok, pid} | {:error, term()}
      def start_link({key, args}) do
        name = {:via, unquote(registry_module), {unquote(registry_name), {__MODULE__, key}}}

        with {:error, {:already_started, pid}} <- GenServer.start_link(__MODULE__, {key, args}, name: name) do
          :ignore
        end
      end

      @doc """
      Starts debouncing the given `t:Buffy.Throttle.key()` for the
      module set `throttle` time. Returns a tuple containing `:ok`
      and the `t:pid()` of the throttle process.

      ## Examples

          iex> throttle(:my_function_arg)
          {:ok, #PID<0.123.0>}

      """
      @impl Buffy.Throttle
      @spec throttle(Buffy.Throttle.args()) :: :ok | {:error, term()}
      def throttle(args) do
        key = args |> :erlang.term_to_binary() |> :erlang.phash2()

        :telemetry.execute(
          [:buffy, :throttle, :throttle],
          %{count: 1},
          %{args: args, key: key, module: __MODULE__}
        )

        case unquote(supervisor_module).start_child(unquote(supervisor_name), {__MODULE__, {key, args}}) do
          {:ok, pid} -> :ok
          :ignore -> :ok
          result -> result
        end
      end

      @doc """
      Returns the maximum amount of jitter in milliseconds. This allows
      for a bit of random delay before calling the `throttle/1` function
      to avoid thundering herd problems.
      """
      @impl Buffy.Throttle
      @spec get_jitter(Buffy.Throttle.args()) :: non_neg_integer()
      def get_jitter(_args), do: unquote(jitter)

      defoverridable get_jitter: 1

      @doc """
      Returns the amount of throttle in milliseconds to wait before calling
      the `throttle/1` function. This function can be overridden to provide
      dynamic throttling based on the passed in arguments.
      """
      @impl Buffy.Throttle
      @spec get_throttle(Buffy.Throttle.args()) :: non_neg_integer()
      def get_throttle(_args), do: unquote(throttle)

      defoverridable get_throttle: 1

      @doc """
      The function that runs after throttle has completed. This function will
      be called with the `t:Buffy.Throttle.key()` and can return anything. The
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
      @impl Buffy.Throttle
      @spec handle_throttle(Buffy.Throttle.args()) :: any()
      def handle_throttle(_args) do
        raise RuntimeError,
          message: "You must implement the `handle_throttle/1` function in your module."
      end

      defoverridable handle_throttle: 1

      @doc false
      @impl GenServer
      @spec init(Buffy.Throttle.state()) :: {:ok, Buffy.Throttle.state()}
      def init({key, args}) do
        Process.send_after(self(), :timeout, unquote(throttle))
        {:ok, {key, args}, {:continue, :measure_memory}}
      end

      @doc false
      @impl GenServer
      @spec handle_continue(:measure_memory, Buffy.Throttle.state()) :: {:noreply, Buffy.Throttle.state()}
      def handle_continue(:measure_memory, {key, args} = state) do
        case Process.info(self(), [:total_heap_size]) do
          [{:total_heap_size, total_heap_size}] ->
            :telemetry.execute(
              [:buffy, :throttle],
              %{
                total_heap_size: total_heap_size
              },
              %{
                args: args,
                key: key,
                module: __MODULE__
              }
            )

          _ ->
            nil
        end

        {:noreply, state}
      end

      @doc false
      @impl GenServer
      @spec handle_info(:timeout, Buffy.Throttle.state()) :: {:stop, :normal, Buffy.Throttle.state()}
      def handle_info(:timeout, {key, args}) do
        jitter = get_jitter(args)
        selected_jitter = max(:rand.uniform(jitter + 1) - 1, 0)

        :telemetry.execute([:buffy, :throttle, :handle, :jitter], %{jitter: selected_jitter}, %{
          args: args,
          key: key,
          module: __MODULE__
        })

        Process.sleep(selected_jitter)

        :telemetry.span(
          [:buffy, :throttle, :handle],
          %{args: args, key: key, module: __MODULE__},
          fn ->
            result = handle_throttle(args)
            {result, %{args: args, key: key, module: __MODULE__, result: result}}
          end
        )

        {:stop, :normal, {key, args}}
      rescue
        e ->
          Logger.error("Error in throttle: #{inspect(e)}")
          {:stop, :normal, {key, args}}
      end
    end
  end
end
