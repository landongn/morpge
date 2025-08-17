defmodule More.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MoreWeb.Telemetry,
      # Start the Ecto repository
      More.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: More.PubSub},
      # Start Finch
      {Finch, name: More.Finch},
      # Start the Endpoint (http/https)
      MoreWeb.Endpoint
      # Start the Entity Supervisor for our MUD engine (temporarily disabled for testing)
      # More.Mud.Supervision.EntitySupervisor
      # Start a worker by calling: More.Worker.start_link(arg)
      # {More.Worker, arg}
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
