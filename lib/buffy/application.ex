defmodule Buffy.Application do
  @moduledoc """
  The Buffy supervisor responsible for starting the default
  `Registry` and `DynamicSupervisor`.
  """

  use Application

  @doc false
  @spec start(Application.start_type(), term()) :: {:ok, pid} | {:error, term()}
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Buffy.Registry},
      {DynamicSupervisor, name: Buffy.DynamicSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
