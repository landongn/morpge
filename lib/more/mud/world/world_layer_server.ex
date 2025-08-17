defmodule More.Mud.World.WorldLayerServer do
  @moduledoc """
  GenServer for managing a single world layer.

  Each layer is responsible for:
  - Managing its map data
  - Processing world ticks
  - Handling entity interactions
  - Communicating with other layers
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts a new world layer server.
  """
  def start_link(opts) do
    layer_id = Keyword.fetch!(opts, :layer_id)
    layer_name = Keyword.fetch!(opts, :layer_name)
    zone_name = Keyword.fetch!(opts, :zone_name)
    tick_interval = Keyword.get(opts, :tick_interval, 3000)

    GenServer.start_link(__MODULE__, {layer_id, layer_name, zone_name, tick_interval},
      name: String.to_atom("#{layer_name}_#{zone_name}")
    )
  end

  @doc """
  Gets the current state of the layer.
  """
  def get_state(layer_name, zone_name) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), :get_state)
  end

  @doc """
  Gets the map data for the layer.
  """
  def get_map(layer_name, zone_name) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), :get_map)
  end

  @doc """
  Gets a character at specific coordinates.
  """
  def get_at(layer_name, zone_name, x, y) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), {:get_at, x, y})
  end

  @doc """
  Sets a character at specific coordinates.
  """
  def set_at(layer_name, zone_name, x, y, char) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), {:set_at, x, y, char})
  end

  @doc """
  Gets entities at a specific position.
  """
  def get_entities_at(layer_name, zone_name, x, y) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), {:get_entities_at, x, y})
  end

  @doc """
  Adds an entity to the layer.
  """
  def add_entity(layer_name, zone_name, entity_data) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), {:add_entity, entity_data})
  end

  @doc """
  Removes an entity from the layer.
  """
  def remove_entity(layer_name, zone_name, entity_id) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), {:remove_entity, entity_id})
  end

  @doc """
  Moves an entity to a new position.
  """
  def move_entity(layer_name, zone_name, entity_id, new_x, new_y) do
    GenServer.call(
      String.to_atom("#{layer_name}_#{zone_name}"),
      {:move_entity, entity_id, new_x, new_y}
    )
  end

  @doc """
  Processes a world tick for this layer.
  """
  def process_world_tick(layer_name, zone_name, tick_data) do
    GenServer.cast(String.to_atom("#{layer_name}_#{zone_name}"), {:world_tick, tick_data})
  end

  @doc """
  Gets connections to other layers.
  """
  def get_connections(layer_name, zone_name) do
    GenServer.call(String.to_atom("#{layer_name}_#{zone_name}"), :get_connections)
  end

  # Server Callbacks

  @impl true
  def init({layer_id, layer_name, zone_name, tick_interval}) do
    Logger.info("Starting world layer server for #{layer_name} in zone #{zone_name}")

    # Load initial data from database
    {:ok, layer} = load_layer_data(layer_id, zone_name)

    # Set up timer for world ticks
    timer_ref = schedule_tick(tick_interval)

    initial_state = %{
      layer_id: layer_id,
      layer_name: layer_name,
      zone_name: zone_name,
      tick_interval: tick_interval,
      timer_ref: timer_ref,
      map: layer.map,
      entities: layer.entities,
      connections: layer.connections,
      last_tick: nil,
      tick_count: 0,
      metadata: layer.metadata || %{}
    }

    Logger.info(
      "World layer #{layer_name} initialized with #{map_size(initial_state.entities)} entities"
    )

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_map, _from, state) do
    {:reply, state.map, state}
  end

  @impl true
  def handle_call({:get_at, x, y}, _from, state) do
    result = More.Mud.World.LayerMap.get_at(state.map, x, y)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:set_at, x, y, char}, _from, state) do
    updated_map = More.Mud.World.LayerMap.set_at(state.map, x, y, char)
    updated_state = %{state | map: updated_map}

    # TODO: Persist changes to database
    Logger.debug("Updated map at (#{x}, #{y}) to '#{char}' in layer #{state.layer_name}")

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:get_entities_at, x, y}, _from, state) do
    entities =
      Enum.filter(state.entities, fn {_id, entity} ->
        entity.x == x and entity.y == y
      end)

    {:reply, entities, state}
  end

  @impl true
  def handle_call({:add_entity, entity_data}, _from, state) do
    entity_id = entity_data.entity_id
    updated_entities = Map.put(state.entities, entity_id, entity_data)
    updated_state = %{state | entities: updated_entities}

    Logger.debug("Added entity #{entity_id} to layer #{state.layer_name}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:remove_entity, entity_id}, _from, state) do
    updated_entities = Map.delete(state.entities, entity_id)
    updated_state = %{state | entities: updated_entities}

    Logger.debug("Removed entity #{entity_id} from layer #{state.layer_name}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:move_entity, entity_id, new_x, new_y}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :entity_not_found}, state}

      entity ->
        updated_entity = %{entity | x: new_x, y: new_y}
        updated_entities = Map.put(state.entities, entity_id, updated_entity)
        updated_state = %{state | entities: updated_entities}

        Logger.debug(
          "Moved entity #{entity_id} to (#{new_x}, #{new_y}) in layer #{state.layer_name}"
        )

        {:reply, :ok, updated_state}
    end
  end

  @impl true
  def handle_call(:get_connections, _from, state) do
    {:reply, state.connections, state}
  end

  @impl true
  def handle_cast({:world_tick, tick_data}, state) do
    Logger.debug("Processing world tick #{tick_data.tick_number} for layer #{state.layer_name}")

    # Process the tick for this layer
    updated_state = process_layer_tick(state, tick_data)

    # Schedule next tick
    timer_ref = schedule_tick(state.tick_interval)

    updated_state = %{
      updated_state
      | last_tick: tick_data.tick_number,
        tick_count: updated_state.tick_count + 1,
        timer_ref: timer_ref
    }

    Logger.info("Layer #{state.layer_name} completed tick #{tick_data.tick_number}")
    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:tick, state) do
    # This is a local tick for this layer
    tick_data = %{
      tick_number: (state.last_tick || 0) + 1,
      timestamp: DateTime.utc_now(),
      layer_name: state.layer_name,
      zone_name: state.zone_name
    }

    # Process the tick
    updated_state = process_layer_tick(state, tick_data)

    # Schedule next tick
    timer_ref = schedule_tick(state.tick_interval)

    updated_state = %{
      updated_state
      | last_tick: tick_data.tick_number,
        tick_count: updated_state.tick_count + 1,
        timer_ref: timer_ref
    }

    Logger.debug("Layer #{state.layer_name} completed local tick #{tick_data.tick_number}")
    {:noreply, updated_state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("World layer server #{state.layer_name} terminating: #{inspect(reason)}")

    # Cancel timer
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    :ok
  end

  # Private Functions

  defp schedule_tick(interval) do
    Process.send_after(self(), :tick, interval)
  end

  defp load_layer_data(_layer_id, zone_name) do
    # Load layer data from database
    # This is a simplified version - in practice, you'd want to handle errors
    layer = %{
      map: %More.Mud.World.LayerMap{
        zone_name: zone_name,
        map_data: create_default_map(20, 20),
        width: 20,
        height: 20
      },
      entities: %{},
      connections: [],
      metadata: %{}
    }

    {:ok, layer}
  end

  defp create_default_map(width, height) do
    # Create a simple default map
    Enum.map(0..(height - 1), fn _y ->
      String.duplicate(".", width)
    end)
    |> Enum.join("\n")
  end

  defp process_layer_tick(state, tick_data) do
    # Process tick based on layer type
    case state.layer_name do
      "ground" -> process_ground_tick(state, tick_data)
      "atmosphere" -> process_atmosphere_tick(state, tick_data)
      "plants" -> process_plants_tick(state, tick_data)
      "structures" -> process_structures_tick(state, tick_data)
      "floor_plans" -> process_floor_plans_tick(state, tick_data)
      "doors" -> process_doors_tick(state, tick_data)
      _ -> state
    end
  end

  defp process_ground_tick(state, _tick_data) do
    # Ground layer processing (e.g., erosion, resource regeneration)
    state
  end

  defp process_atmosphere_tick(state, _tick_data) do
    # Atmosphere layer processing (e.g., weather changes, visibility)
    state
  end

  defp process_plants_tick(state, _tick_data) do
    # Plants layer processing (e.g., growth, seasonal changes)
    state
  end

  defp process_structures_tick(state, _tick_data) do
    # Structures layer processing (e.g., decay, maintenance)
    state
  end

  defp process_floor_plans_tick(state, _tick_data) do
    # Floor plans layer processing (e.g., room state changes)
    state
  end

  defp process_doors_tick(state, _tick_data) do
    # Doors layer processing (e.g., lock/unlock, damage)
    state
  end
end
