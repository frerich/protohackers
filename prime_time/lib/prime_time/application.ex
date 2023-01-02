defmodule PrimeTime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT", "47341"))

    children = [
      {Task.Supervisor, name: PrimeTime.ClientSupervisor},
      {Task, fn -> PrimeTime.Server.listen(port) end}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PrimeTime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
