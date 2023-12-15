defmodule Buffy.Buffer do
  @moduledoc """
  ## Example Usage

  You'll first need to create a module that will be used to buffer.

      defmodule MyTask do
        use Buffy.Buffer,
          throttle: :timer.minutes(2)

        def handle_buffer(args) do
          # Do something with args
        end
      end

  Next, you can use the `buffer/1` function with the registered module.

      iex> MyTask.buffer(args)
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

        defmodule MyBuffer do
          use Buffy.Buffer,
            registry_module: Horde.Registry,
            registry_name: MyApp.HordeRegistry,
            supervisor_module: Horde.DynamicSupervisor,
            supervisor_name: MyApp.HordeDynamicSupervisor,
            throttle: :timer.minutes(2)

          def handle_buffer(args) do
            # Do something with args
          end
        end

  ## Telemetry

  These are the events that are called by the `Buffy.Throttle` module:

  - `[:buffy, :buffer, :buffer]` - Emitted when the `throttle/1` function is called.
  - `[:buffy, :buffer, :handle, :start]` - Emitted at the start of the `handle_throttle/1` function.
  - `[:buffy, :buffer, :handle, :stop]` - Emitted at the end of the `handle_throttle/1` function.
  - `[:buffy, :buffer, :handle, :exception]` - Emitted when an error is raised in the `handle_throttle/1` function.

  All of these events will have the following metadata:

  - `:args` - The arguments passed to the `buffer/1` function.
  - `:key` - A hash of the passed arguments used to deduplicate the throttled function.
  - `:module` - The module using `Buffy.Buffer`.

  With the additional metadata for `[:buffy, :buffer, :handle, :stop]`:

  - `:result` - The return value of the `handle_buffer/1` function.

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
  A function to call the throttle. This will always return a tuple of `{:ok, pid()}`
  and wait the configured `throttle` time before calling the `c:handle_throttle/1`
  function.
  """
  @callback buffer(args :: args(), args :: args()) :: {:ok, pid()}

  @doc """
  The function called after the throttle has completed. This function will
  receive the arguments passed to the `throttle/1` function.
  """
  @callback handle_buffer(args()) :: any()

  defmacro __using__(opts) do
    quote do
      use Buffy.Throttle, unquote(opts)

      @doc """
      Starts debouncing the given `t:Buffy.Buffer.key()` for the
      module set `throttle` time. Returns a tuple containing `:ok`
      and the `t:pid()` of the buffered process.

      ## Examples

          iex> throttle(:my_function_arg)
          {:ok, #PID<0.123.0>}

      """
      @impl Buffy.Buffer
      def buffer(key, args) do
        key = key |> :erlang.term_to_binary() |> :erlang.phash2()

        :telemetry.execute(
          [:buffy, :buffer, :buffer],
          %{count: 1},
          %{args: args, key: key, module: __MODULE__}
        )

        case unquote(supervisor_module).start_child(unquote(supervisor_name), {__MODULE__, {key, args}}) do
          {:ok, pid} ->
            {:ok, pid}

          :ignore ->
            with [{pid, _}] <- unquote(registry_module).lookup(unquote(registry_name), {__MODULE__, key}),
              :ok <- GenServer.cast(pid, {:insert, args}) do
            {:ok, pid}
            end
        end
      end

      def handle_cast({:insert, args}, {key, buffer}) do
        {:norely, {key, [args | buffer]}}
      end

      @impl Buffy.Throttle
      def handle_throttle(args), do: handle_buffer(args)

      @spec handle_buffer(Buffy.Buffer.args()) :: any()
      def handle_buffer(_args) do
        raise RuntimeError,
          message: "you must implement the `handle_buffer/1` function in your module."
      end

      defoverridable handle_buffer: 1
    end
  end
end
