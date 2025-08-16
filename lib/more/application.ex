defmodule More.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MoreWeb.Telemetry,
      More.Repo,
      {DNSCluster, query: Application.get_env(:more, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: More.PubSub},
      # Start a worker by calling: More.Worker.start_link(arg)
      # {More.Worker, arg},
      # Start to serve requests, typically the last entry
      MoreWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: More.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
