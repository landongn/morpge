defmodule More.Mud.World.WorldManager do
  @moduledoc """
  Central manager for the entire world system.

  This module provides:
  - Unified interface for world operations
  - Layer coordination and management
  - World tick processing
  - Zone management
  - Player interaction handling
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts the world manager.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current world state.
  """
  def get_world_state do
    GenServer.call(__MODULE__, :get_world_state)
  end

  @doc """
  Gets all layers for a specific zone.
  """
  def get_zone_layers(zone_name) do
    GenServer.call(__MODULE__, {:get_zone_layers, zone_name})
  end

  @doc """
  Gets the combined view of all layers at a specific position.
  """
  def get_position_view(zone_name, x, y) do
    GenServer.call(__MODULE__, {:get_position_view, zone_name, x, y})
  end

  @doc """
  Gets a rectangular region view from all layers.
  """
  def get_region_view(zone_name, x, y, width, height) do
    GenServer.call(__MODULE__, {:get_region_view, zone_name, x, y, width, height})
  end

  @doc """
  Moves a player to a new position.
  """
  def move_player(player_id, zone_name, x, y) do
    GenServer.call(__MODULE__, {:move_player, player_id, zone_name, x, y})
  end

  @doc """
  Adds an entity to a specific layer.
  """
  def add_entity_to_layer(layer_name, zone_name, entity_data) do
    GenServer.call(__MODULE__, {:add_entity_to_layer, layer_name, zone_name, entity_data})
  end

  @doc """
  Removes an entity from a specific layer.
  """
  def remove_entity_from_layer(layer_name, zone_name, entity_id) do
    GenServer.call(__MODULE__, {:remove_entity_from_layer, layer_name, zone_name, entity_id})
  end

  @doc """
  Processes a world tick for all layers.
  """
  def process_world_tick(tick_data) do
    GenServer.cast(__MODULE__, {:world_tick, tick_data})
  end

  @doc """
  Gets information about all active layers.
  """
  def get_layer_statuses do
    GenServer.call(__MODULE__, :get_layer_statuses)
  end

  @doc """
  Creates a new zone with all required layers.
  """
  def create_zone(zone_name, zone_config \\ %{}) do
    GenServer.call(__MODULE__, {:create_zone, zone_name, zone_config})
  end

  @doc """
  Destroys a zone and all its layers.
  """
  def destroy_zone(zone_name) do
    GenServer.call(__MODULE__, {:destroy_zone, zone_name})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting world manager")

    # Start the world layer supervisor
    {:ok, _pid} = More.Mud.Supervision.WorldLayerSupervisor.start_link([])

    # Start the world layer registry
    {:ok, _pid} = More.Mud.Registry.WorldLayerRegistry.start_link([])

    # Set up timer for world ticks
    timer_ref = schedule_world_tick()

    initial_state = %{
      zones: %{},
      players: %{},
      # 3 seconds
      world_tick_interval: 3000,
      timer_ref: timer_ref,
      last_world_tick: nil,
      world_tick_count: 0,
      metadata: %{}
    }

    Logger.info("World manager initialized")
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_world_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_zone_layers, zone_name}, _from, state) do
    layers = More.Mud.Registry.WorldLayerRegistry.layers_for_zone(zone_name)
    {:reply, layers, state}
  end

  @impl true
  def handle_call({:get_position_view, zone_name, x, y}, _from, state) do
    view = build_position_view(zone_name, x, y)
    {:reply, view, state}
  end

  @impl true
  def handle_call({:get_region_view, zone_name, x, y, width, height}, _from, state) do
    view = build_region_view(zone_name, x, y, width, height)
    {:reply, view, state}
  end

  @impl true
  def handle_call({:move_player, player_id, zone_name, x, y}, _from, state) do
    result = handle_player_movement(player_id, zone_name, x, y)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_entity_to_layer, layer_name, zone_name, entity_data}, _from, state) do
    result = More.Mud.World.WorldLayerServer.add_entity(layer_name, zone_name, entity_data)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:remove_entity_from_layer, layer_name, zone_name, entity_id}, _from, state) do
    result = More.Mud.World.WorldLayerServer.remove_entity(layer_name, zone_name, entity_id)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_layer_statuses, _from, state) do
    statuses = More.Mud.Supervision.WorldLayerSupervisor.get_layer_statuses()
    {:reply, statuses, state}
  end

  @impl true
  def handle_call({:create_zone, zone_name, zone_config}, _from, state) do
    result = create_zone_with_layers(zone_name, zone_config)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:destroy_zone, zone_name}, _from, state) do
    result = destroy_zone_and_layers(zone_name)
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:world_tick, tick_data}, state) do
    Logger.info("Processing world tick #{tick_data.tick_number}")

    # Process tick for all active layers
    process_all_layer_ticks(tick_data)

    # Update world state
    updated_state = %{
      state
      | last_world_tick: tick_data.tick_number,
        world_tick_count: state.world_tick_count + 1
    }

    # Schedule next world tick
    timer_ref = schedule_world_tick()
    updated_state = %{updated_state | timer_ref: timer_ref}

    Logger.info("World tick #{tick_data.tick_number} completed")
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:world_tick, state) do
    # This is a local world tick
    tick_data = %{
      tick_number: (state.last_world_tick || 0) + 1,
      timestamp: DateTime.utc_now(),
      source: :local
    }

    # Process the tick
    process_all_layer_ticks(tick_data)

    # Update world state
    updated_state = %{
      state
      | last_world_tick: tick_data.tick_number,
        world_tick_count: state.world_tick_count + 1
    }

    # Schedule next world tick
    timer_ref = schedule_world_tick()
    updated_state = %{updated_state | timer_ref: timer_ref}

    Logger.info("Local world tick #{tick_data.tick_number} completed")
    {:noreply, updated_state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("World manager terminating: #{inspect(reason)}")

    # Cancel timer
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    :ok
  end

  # Private Functions

  defp schedule_world_tick do
    # 3 seconds
    Process.send_after(self(), :world_tick, 3000)
  end

  defp build_position_view(zone_name, x, y) do
    # Get all layers for this zone
    layers = More.Mud.Registry.WorldLayerRegistry.layers_for_zone(zone_name)

    # Build a combined view from all layers
    Enum.reduce(layers, %{}, fn {{layer_name, _zone}, _pid, _metadata}, acc ->
      case More.Mud.World.WorldLayerServer.get_at(layer_name, zone_name, x, y) do
        nil -> acc
        char -> Map.put(acc, layer_name, char)
      end
    end)
  end

  defp build_region_view(zone_name, x, y, width, height) do
    # Get all layers for this zone
    layers = More.Mud.Registry.WorldLayerRegistry.layers_for_zone(zone_name)

    # Build a combined view from all layers
    Enum.reduce(layers, %{}, fn {{layer_name, _zone}, _pid, _metadata}, acc ->
      case More.Mud.World.WorldLayerServer.get_map(layer_name, zone_name) do
        nil ->
          acc

        map ->
          region = More.Mud.World.LayerMap.get_region(map, x, y, width, height)
          Map.put(acc, layer_name, region)
      end
    end)
  end

  defp handle_player_movement(_player_id, _zone_name, _x, _y) do
    # TODO: Implement player movement logic
    # This would involve:
    # - Checking if the move is valid
    # - Updating player position
    # - Notifying relevant layers
    # - Handling zone transitions
    :ok
  end

  defp process_all_layer_ticks(tick_data) do
    # Get all active layers
    active_layers = More.Mud.Registry.WorldLayerRegistry.active_layers()

    # Process tick for each layer
    Enum.each(active_layers, fn {{layer_name, zone_name}, _pid, _metadata} ->
      More.Mud.World.WorldLayerServer.process_world_tick(layer_name, zone_name, tick_data)
    end)
  end

  defp create_zone_with_layers(zone_name, _zone_config) do
    # Create the default layers for this zone
    default_layers = [
      {"ground", 1, "Ground terrain and foundation"},
      {"atmosphere", 2, "Environmental effects and visibility"},
      {"plants", 3, "Vegetation and natural resources"},
      {"structures", 4, "Buildings and architectural elements"},
      {"floor_plans", 5, "Interior layouts and room connections"},
      {"doors", 6, "Passageways and zone transitions"}
    ]

    # Start layer servers for each layer
    results =
      Enum.map(default_layers, fn {layer_name, order, description} ->
        layer_id = Ecto.UUID.generate()

        case More.Mud.Supervision.WorldLayerSupervisor.start_layer(
               layer_id,
               layer_name,
               zone_name,
               3000
             ) do
          {:ok, _pid} -> {:ok, {layer_name, order, description}}
          {:error, reason} -> {:error, {layer_name, reason}}
        end
      end)

    # Check if all layers were created successfully
    case Enum.find(results, fn {status, _data} -> status == :error end) do
      nil ->
        Logger.info("Successfully created zone #{zone_name} with all layers")
        {:ok, results}

      {:error, {layer_name, reason}} ->
        Logger.error(
          "Failed to create layer #{layer_name} for zone #{zone_name}: #{inspect(reason)}"
        )

        {:error, "Failed to create layer #{layer_name}"}
    end
  end

  defp destroy_zone_and_layers(zone_name) do
    # Get all layers for this zone
    layers = More.Mud.Registry.WorldLayerRegistry.layers_for_zone(zone_name)

    # Stop all layer servers
    results =
      Enum.map(layers, fn {{layer_name, _zone}, _pid, _metadata} ->
        case More.Mud.Supervision.WorldLayerSupervisor.stop_layer(layer_name, zone_name) do
          :ok -> {:ok, layer_name}
          {:error, reason} -> {:error, {layer_name, reason}}
        end
      end)

    # Check if all layers were stopped successfully
    case Enum.find(results, fn {status, _data} -> status == :error end) do
      nil ->
        Logger.info("Successfully destroyed zone #{zone_name} and all layers")
        {:ok, results}

      {:error, {layer_name, reason}} ->
        Logger.error(
          "Failed to stop layer #{layer_name} for zone #{zone_name}: #{inspect(reason)}"
        )

        {:error, "Failed to stop layer #{layer_name}"}
    end
  end
end
