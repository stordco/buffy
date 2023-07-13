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

    - `:registry_module` (`atom`) - Optional. A module that implements the `Registry` behaviour. If you are running in a distributed instance, you can set this value to `Horde.Registry`. Defaults to `Registry`.

    - `:registry_name` (`atom`) - Optional. The name of the registry to use. Defaults to the built in Buffy registry, but if you are running in a distributed instance you can set this value to a named `Horde.Registry` process. Defaults to `Buffy.Registry`.

    - `:restart` (`:permanent` | `:temporary` | `:transient`) - Optional. The restart strategy to use for the GenServer. Defaults to `:temporary`.

    - `:supervisor_module` (`atom`) - Optional. A module that implements the `DynamicSupervisor` behaviour. If you are running in a distributed instance, you can set this value to `Horde.DynamicSupervisor`. Defaults to `DynamicSupervisor`.

    - `:supervisor_name` (`atom`) - Optional. The name of the dynamic supervisor to use. Defaults to the built in Buffy dynamic supervisor, but if you are running in a distributed instance you can set this value to a named `Horde.DynamicSupervisor` process. Defaults to `Buffy.DynamicSupervisor`.

    - :throttle (`non_neg_integer`) - Required. The amount of time to wait before invoking the function. This value is in milliseconds.

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

  @doc """
  A function to call the throttle. This will always return a tuple of `{:ok, pid()}`
  and wait the configured `throttle` time before calling the `c:handle_throttle/1`
  function.
  """
  @callback throttle(args :: args()) :: {:ok, pid()}

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

    quote do
      @behaviour Buffy.Throttle

      use GenServer, restart: unquote(restart)

      require Logger

      @doc false
      @spec start_link(Buffy.Throttle.args()) :: {:ok, pid} | :ignore
      def start_link(args) do
        key = :erlang.phash2(args)
        name = {:via, unquote(registry_module), {unquote(registry_name), {__MODULE__, key}}}

        with {:error, {:already_started, _pid}} <- GenServer.start_link(__MODULE__, args, name: name) do
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
      @spec throttle(Buffy.Throttle.args()) :: {:ok, pid()}
      def throttle(args) do
        unquote(supervisor_module).start_child(unquote(supervisor_name), {__MODULE__, args})
      end

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
      @spec init(Buffy.Throttle.args()) :: {:ok, Buffy.Throttle.args()}
      def init(args) do
        Process.send_after(self(), :timeout, unquote(throttle))
        {:ok, args}
      end

      @doc false
      @impl GenServer
      @spec handle_info(:timeout, Buffy.Throttle.args()) :: {:stop, :normal, Buffy.Throttle.args()}
      def handle_info(:timeout, args) do
        handle_throttle(args)
        {:stop, :normal, args}
      rescue
        e ->
          Logger.error("Error in throttle: #{inspect(e)}")
          {:stop, :normal, args}
      end
    end
  end
end
