defmodule More.Mud.Supervision.MobSupervisor do
  @moduledoc """
  Supervisor for all mob entities.

  Strategy: :one_for_one
  Restart: :temporary (mobs restart based on spawn rules)
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Mob Supervisor")
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Mob Supervisor")

    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Starts a new mob entity.
  """
  def start_mob(entity_id, entity_type, components) do
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
  Stops a mob entity.
  """
  def stop_mob(entity_id) do
    case Supervisor.terminate_child(__MODULE__, entity_id) do
      :ok -> Supervisor.delete_child(__MODULE__, entity_id)
      {:error, :not_found} -> {:error, :mob_not_found}
      error -> error
    end
  end

  @doc """
  Gets all active mob PIDs.
  """
  def get_mob_pids do
    Supervisor.which_children(__MODULE__)
    |> Enum.filter(fn {_id, pid, _type, _modules} -> is_pid(pid) and pid != :undefined end)
    |> Enum.map(fn {_id, pid, _type, _modules} -> pid end)
  end

  @doc """
  Gets the count of active mobs.
  """
  def get_mob_count do
    Supervisor.count_children(__MODULE__)
    |> Map.get(:active)
  end
end
