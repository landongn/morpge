defmodule More.Mud.Supervision.NpcSupervisor do
  @moduledoc """
  Supervisor for all NPC entities.

  Strategy: :one_for_one
  Restart: :temporary (NPCs restart only when explicitly requested)
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting NPC Supervisor")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing NPC Supervisor")

    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Starts a new NPC entity.
  """
  def start_npc(entity_id, entity_type, components) do
    child_spec = %{
      id: entity_id,
      start:
        {More.Mud.Entities.Entity, :start_link,
         [entity_id: entity_id, entity_type: entity_type, components: components]},
      restart: :temporary,
      shutdown: 5000,
      type: :worker
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops an NPC entity.
  """
  def stop_npc(entity_id) do
    case Supervisor.terminate_child(__MODULE__, entity_id) do
      :ok -> Supervisor.delete_child(__MODULE__, entity_id)
      {:error, :not_found} -> {:error, :npc_not_found}
      error -> error
    end
  end

  @doc """
  Gets all active NPC PIDs.
  """
  def get_npc_pids do
    Supervisor.which_children(__MODULE__)
    |> Enum.filter(fn {_id, pid, _type, _modules} -> is_pid(pid) and pid != :undefined end)
    |> Enum.map(fn {_id, pid, _type, _modules} -> pid end)
  end

  @doc """
  Gets the count of active NPCs.
  """
  def get_npc_count do
    Supervisor.count_children(__MODULE__)
    |> Map.get(:active)
  end
end
