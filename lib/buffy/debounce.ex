defmodule Buffy.Debounce do
  @moduledoc """
  The `Buffy.Debounce` module will wait for a specified amount of time before
  invoking the function. If the function is called again before the time has
  elapsed, the timer will be reset and the function will be called again after
  the specified amount of time.

  ## Example Usage

  You'll first need to create a module that will be used to debounce.

      defmodule MyTask do
        use Buffy.Debounce,
          debounce: :timer.minutes(2)

        def handle_debounce(args) do
          # Do something with args
        end
      end

  Next, you can use the `debounce/1` function with the registered module.

      iex> MyTask.debounce(args)
      :ok

  ## Options

    - :debounce (`non_neg_integer`) - Required. The amount of time to wait before invoking the function. This value is in milliseconds.

    - `:registry_module` (`atom`) - Optional. A module that implements the `Registry` behaviour. If you are running in a distributed instance, you can set this value to `Horde.Registry`. Defaults to `Registry`.

    - `:registry_name` (`atom`) - Optional. The name of the registry to use. Defaults to the built in Buffy registry, but if you are running in a distributed instance you can set this value to a named `Horde.Registry` process. Defaults to `Buffy.Registry`.

    - `:restart` (`:permanent` | `:temporary` | `:transient`) - Optional. The restart strategy to use for the GenServer. Defaults to `:temporary`.

    - `:supervisor_module` (`atom`) - Optional. A module that implements the `DynamicSupervisor` behaviour. If you are running in a distributed instance, you can set this value to `Horde.DynamicSupervisor`. Defaults to `DynamicSupervisor`.

    - `:supervisor_name` (`atom`) - Optional. The name of the dynamic supervisor to use. Defaults to the built in Buffy dynamic supervisor, but if you are running in a distributed instance you can set this value to a named `Horde.DynamicSupervisor` process. Defaults to `Buffy.DynamicSupervisor`.

  ## Using with Horde

  If you are running Elixir in a cluster, you can utilize `Horde` to only run one of your debounced functions at a time. To do this, you'll need to set the `:registry_module` and `:supervisor_module` options to `Horde.Registry` and `Horde.DynamicSupervisor` respectively. You'll also need to set the `:registry_name` and `:supervisor_name` options to the name of the Horde registry and dynamic supervisor you want to use.

        defmodule MyDebouncer do
          use Buffy.Debounce,
            debounce: :timer.minutes(2),
            registry_module: Horde.Registry,
            registry_name: MyApp.HordeRegistry,
            supervisor_module: Horde.DynamicSupervisor,
            supervisor_name: MyApp.HordeDynamicSupervisor

          def handle_debounce(args) do
            # Do something with args
          end
        end

  """

  @typedoc """
  A list of arbitrary arguments that are used for the `c:handle_debounce/1`
  function.
  """
  @type args :: term()

  @typedoc """
  A unique key for debouncing. This is used for GenServer uniqueness and is
  generated from hashing all of the args.
  """
  @type key :: term()

  @doc """
  A function to call the debounce. This will always return `:ok` and wait
  the configured `debounce` time before calling the `c:handle_debounce/1`
  function.
  """
  @callback debounce(args :: args()) :: :ok

  @doc """
  The function called after the debounce has completed. This function will
  receive the arguments passed to the `debounce/1` function.
  """
  @callback handle_debounce(args()) :: any()

  defmacro __using__(opts) do
    debounce = Keyword.fetch!(opts, :debounce)
    registry_module = Keyword.get(opts, :registry_module, Registry)
    registry_name = Keyword.get(opts, :registry_name, Buffy.Registry)
    restart = Keyword.get(opts, :restart, :temporary)
    supervisor_module = Keyword.get(opts, :supervisor_module, DynamicSupervisor)
    supervisor_name = Keyword.get(opts, :supervisor_name, Buffy.DynamicSupervisor)

    quote do
      @behaviour Buffy.Debounce

      use GenServer, restart: unquote(restart)

      require Logger

      @doc false
      @spec start_link(Buffy.Debounce.args()) :: {:ok, pid} | :ignore
      def start_link(args) do
        key = :erlang.phash2(args)
        name = {:via, unquote(registry_module), {unquote(registry_name), {__MODULE__, key}}}

        with {:error, {:already_started, _pid}} <- GenServer.start_link(__MODULE__, args, name: name) do
          :ignore
        end
      end

      @doc """
      Starts debouncing the given `t:Buffy.Debounce.key()` for the
      module set `debounce` time. Returns `:ok`.

      ## Examples

          iex> debounce(:my_function_arg)
          :ok

      """
      @impl Buffy.Debounce
      @spec debounce(Buffy.Debounce.args()) :: :ok
      def debounce(args) do
        _ = unquote(supervisor_module).start_child(unquote(supervisor_name), {__MODULE__, args})
        :ok
      end

      @doc """
      The function that runs after debounce has completed. This function will
      be called with the `t:Buffy.Debounce.key()` and can return anything. The
      return value is ignored. If an error is raised, it will be logged and
      ignored.

      ## Examples

      A simple example of implementing the `c:Buffy.Debounce.handle_debounce/1`
      callback:

          def handle_debounce(args) do
            # Do some work
          end

      Handling errors in the `c:Buffy.Debounce.handle_debounce/1` callback:

          def handle_debounce(args) do
            # Do some work
          rescue
            e ->
              # Do something with a raised error
          end

      """
      @impl Buffy.Debounce
      @spec handle_debounce(Buffy.Debounce.args()) :: any()
      def handle_debounce(_args) do
        raise RuntimeError,
          message: "You must implement the `handle_debounce/1` function in your module."
      end

      defoverridable handle_debounce: 1

      @doc false
      @impl GenServer
      @spec init(Buffy.Debounce.args()) :: {:ok, Buffy.Debounce.args()}
      def init(args) do
        Process.send_after(self(), :timeout, unquote(debounce))
        {:ok, args}
      end

      @doc false
      @impl GenServer
      @spec handle_info(:timeout, Buffy.Debounce.args()) :: {:stop, :normal, Buffy.Debounce.args()}
      def handle_info(:timeout, args) do
        handle_debounce(args)
        {:stop, :normal, args}
      rescue
        e ->
          Logger.error("Error in debounce: #{inspect(e)}")
          {:stop, :normal, args}
      end
    end
  end
end
