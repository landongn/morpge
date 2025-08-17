defmodule More.Mud.Supervision.WorldLayerSupervisor do
  @moduledoc """
  Supervisor for managing all world layer servers.

  This supervisor is responsible for:
  - Starting and stopping layer servers
  - Monitoring layer health
  - Coordinating layer interactions
  - Managing layer lifecycle
  """

  use Supervisor
  require Logger

  @doc """
  Starts the world layer supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a new layer server for a specific layer and zone.
  """
  def start_layer(layer_id, layer_name, zone_name, tick_interval \\ 3000) do
    child_spec = %{
      id: {layer_name, zone_name},
      start:
        {More.Mud.World.WorldLayerServer, :start_link,
         [
           layer_id: layer_id,
           layer_name: layer_name,
           zone_name: zone_name,
           tick_interval: tick_interval
         ]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }

    case Supervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        Logger.info("Started world layer server for #{layer_name} in zone #{zone_name}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("World layer server for #{layer_name} in zone #{zone_name} already running")
        {:ok, pid}

      {:error, reason} ->
        Logger.error(
          "Failed to start world layer server for #{layer_name} in zone #{zone_name}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Stops a layer server.
  """
  def stop_layer(layer_name, zone_name) do
    case Supervisor.terminate_child(__MODULE__, {layer_name, zone_name}) do
      :ok ->
        Logger.info("Stopped world layer server for #{layer_name} in zone #{zone_name}")
        :ok

      {:error, :not_found} ->
        Logger.warning("World layer server for #{layer_name} in zone #{zone_name} not found")
        :ok

      {:error, reason} ->
        Logger.error(
          "Failed to stop world layer server for #{layer_name} in zone #{zone_name}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Gets the status of all layer servers.
  """
  def get_layer_statuses do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {id, pid, type, modules} ->
      case Process.info(pid, :status) do
        {:status, status} ->
          %{
            id: id,
            pid: pid,
            type: type,
            modules: modules,
            status: status
          }

        nil ->
          %{
            id: id,
            pid: nil,
            type: type,
            modules: modules,
            status: :terminated
          }
      end
    end)
  end

  @doc """
  Restarts a layer server.
  """
  def restart_layer(layer_name, zone_name) do
    case Supervisor.restart_child(__MODULE__, {layer_name, zone_name}) do
      {:ok, pid} ->
        Logger.info("Restarted world layer server for #{layer_name} in zone #{zone_name}")
        {:ok, pid}

      {:error, :not_found} ->
        Logger.warning("World layer server for #{layer_name} in zone #{zone_name} not found")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Failed to restart world layer server for #{layer_name} in zone #{zone_name}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @doc """
  Gets information about a specific layer server.
  """
  def get_layer_info(layer_name, zone_name) do
    case Registry.lookup(More.Mud.Registry.WorldLayerRegistry, {layer_name, zone_name}) do
      [{pid, _}] ->
        case Process.info(pid, [:status, :memory, :message_queue_len]) do
          [{:status, status}, {:memory, memory}, {:message_queue_len, queue_len}] ->
            %{
              layer_name: layer_name,
              zone_name: zone_name,
              pid: pid,
              status: status,
              memory: memory,
              message_queue_len: queue_len
            }

          _ ->
            %{
              layer_name: layer_name,
              zone_name: zone_name,
              pid: pid,
              status: :unknown
            }
        end

      [] ->
        nil
    end
  end

  # Supervisor Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting world layer supervisor")

    children = [
      # Add any permanent children here if needed
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
