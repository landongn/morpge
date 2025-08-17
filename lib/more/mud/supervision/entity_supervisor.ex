defmodule More.Mud.Supervision.EntitySupervisor do
  @moduledoc """
  Top-level supervisor for all entities in the MUD engine.

  Manages:
  - Entity Registry (GenServer)
  - PlayerSupervisor
  - NpcSupervisor
  - MobSupervisor
  - ItemSupervisor

  Each entity type gets its own supervisor for fault isolation.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Entity Supervisor")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Entity Supervisor")

    children = [
      # Entity Registry - must start first as a GenServer
      {More.Mud.Registry.EntityRegistry, []},

      # Entity type supervisors
      {More.Mud.Supervision.PlayerSupervisor, []},
      {More.Mud.Supervision.NpcSupervisor, []},
      {More.Mud.Supervision.MobSupervisor, []},
      {More.Mud.Supervision.ItemSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
