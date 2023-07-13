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
          concurrency: 0,
          debounce: 0

        def handle_debounce(args) do
          # Do something with args
        end
      end

  Next, you can use the `debounce/1` function with the registered module.

      iex> MyTask.debounce(args)
      :ok

  ## Options

    - :concurrency (`non_neg_integer` or `:infinity`) - Required. The maximum number of functions that will be ran at once. By default this is set to :infinity which means there are no limits to the number of functions that can be ran at once.

      If you are using resources like a database or API, then you might want to limit the number of functions that can be ran at once. Just set this value to a non-negative integer.

      The default value is :infinity.

    - :debounce (`non_neg_integer`) - Required. The amount of time to wait before invoking the function. This value is in milliseconds.
  """

  defmacro __using__(module_opts) do
    quote location: :keep do
      use GenServer

      @typedoc "Internal state module."
      @type state :: %{
              concurrency: non_neg_integer() | :infinity,
              debounce: non_neg_integer(),
              timer_references: %{required(binary()) => reference()},
              arg_references: %{required(binary()) => term()}
            }

      def start_link(opts) do
        full_opts = Keyword.merge(unquote(module_opts), opts)
        GenServer.start_link(__MODULE__, full_opts, name: __MODULE__)
      end

      @doc """
      Debounces the given arguments.

      ## Examples

          iex> debounce(args)
          :ok

      """
      def debounce(args) do
        GenServer.cast(__MODULE__, {:debounce, args})
      end

      @doc false
      @spec init(Keyword.t()) :: {:ok, state()}
      def init(opts) do
        concurrency = Keyword.fetch!(opts, :concurrency)
        debounce = Keyword.fetch!(opts, :debounce)

        {:ok,
         %{
           concurrency: concurrency,
           debounce: debounce,
           timer_references: %{},
           arg_references: %{}
         }}
      end

      @doc false
      @spec handle_cast({:debounce, term()}, state()) :: {:noreply, state()}
      def handle_cast({:debounce, args}, state) do
        # TODO: actually debounce
        apply(__MODULE__, :handle_debounce, [args])
        {:noreply, state}
      end

      def handle_debounce(_args) do
        raise RuntimeError,
          message: "You must implement the `handle_debounce/1` function in your module."
      end

      defoverridable(handle_debounce: 1)
    end
  end
end
