defmodule Buffy.Application do
  @moduledoc """
  The Buffy supervisor responsible for starting the default
  registry and task supervisor.
  """

  use Application

  @doc false
  @spec start(Application.start_type(), term()) :: {:ok, pid} | {:error, term()}
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Buffy.Registry},
      {Task.Supervisor, name: Buffy.TaskSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
