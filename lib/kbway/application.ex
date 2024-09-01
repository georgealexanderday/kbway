defmodule Kbway.Application do
  @impl true
  def start(_type, _args) do
    children = [
      Kbway
    ]

    opts = [strategy: :one_for_one, name: Kbway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
