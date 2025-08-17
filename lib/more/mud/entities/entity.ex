defmodule More.Mud.Entities.Entity do
  @moduledoc """
  Base Entity GenServer that all game entities inherit from.

  Each entity is a GenServer with:
  - Component-based behavior system
  - Supervised lifecycle management
  - Fault tolerance and recovery
  - World tick processing
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts a new entity with the given ID and initial components.
  """
  def start_link(opts) do
    entity_id = Keyword.fetch!(opts, :entity_id)
    entity_type = Keyword.fetch!(opts, :entity_type)
    initial_components = Keyword.get(opts, :components, %{})
    registry_name = Keyword.get(opts, :registry_name, More.Mud.Registry.EntityRegistry)

    GenServer.start_link(__MODULE__, {entity_id, entity_type, initial_components, registry_name})
  end

  @doc """
  Gets the current entity state.
  """
  def get_state(entity_pid) do
    GenServer.call(entity_pid, :get_state)
  end

  @doc """
  Adds a component to the entity.
  """
  def add_component(entity_pid, component_type, component_data) do
    GenServer.call(entity_pid, {:add_component, component_type, component_data})
  end

  @doc """
  Updates a component field.
  """
  def update_component(entity_pid, component_type, field, value) do
    GenServer.call(entity_pid, {:update_component, component_type, field, value})
  end

  @doc """
  Gets a component from the entity.
  """
  def get_component(entity_pid, component_type) do
    GenServer.call(entity_pid, {:get_component, component_type})
  end

  @doc """
  Removes a component from the entity.
  """
  def remove_component(entity_pid, component_type) do
    GenServer.call(entity_pid, {:remove_component, component_type})
  end

  @doc """
  Checks if the entity has a specific component.
  """
  def has_component?(entity_pid, component_type) do
    GenServer.call(entity_pid, {:has_component?, component_type})
  end

  @doc """
  Processes a world tick for this entity.
  """
  def process_world_tick(entity_pid, tick_data) do
    GenServer.cast(entity_pid, {:world_tick, tick_data})
  end

  @doc """
  Gets the entity's current position.
  """
  def get_position(entity_pid) do
    GenServer.call(entity_pid, :get_position)
  end

  @doc """
  Sets the entity's position.
  """
  def set_position(entity_pid, zone, room, coordinates \\ nil) do
    GenServer.call(entity_pid, {:set_position, zone, room, coordinates})
  end

  @doc """
  Gets the entity's current status.
  """
  def get_status(entity_pid) do
    GenServer.call(entity_pid, :get_status)
  end

  @doc """
  Sets the entity's status.
  """
  def set_status(entity_pid, status) do
    GenServer.call(entity_pid, {:set_status, status})
  end

  # Server Callbacks

  @impl true
  def init({entity_id, entity_type, initial_components, registry_name}) do
    Logger.info("Starting entity #{entity_id} of type #{entity_type}")

    initial_state = %{
      entity_id: entity_id,
      entity_type: entity_type,
      components: initial_components,
      registry_name: registry_name,
      position: %{
        zone: nil,
        room: nil,
        coordinates: nil
      },
      status: :spawning,
      created_at: DateTime.utc_now(),
      last_tick: nil,
      metadata: %{}
    }

    # Register this entity with the registry
    registry_name.register(entity_id, self(), %{
      type: entity_type,
      components: Map.keys(initial_components),
      status: :spawning
    })

    # Set status to active after successful initialization
    updated_state = %{initial_state | status: :active}

    # Update registry with active status
    registry_name.update_metadata(entity_id, :status, :active)

    {:ok, updated_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_component, component_type, component_data}, _from, state) do
    updated_components = Map.put(state.components, component_type, component_data)
    updated_state = %{state | components: updated_components}

    # Update registry with new component
    registry_name = state.registry_name
    registry_name.update_metadata(state.entity_id, :components, Map.keys(updated_components))

    Logger.debug("Added component #{component_type} to entity #{state.entity_id}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:update_component, component_type, field, value}, _from, state) do
    case Map.get(state.components, component_type) do
      nil ->
        {:reply, {:error, :component_not_found}, state}

      component ->
        updated_component = Map.put(component, field, value)
        updated_components = Map.put(state.components, component_type, updated_component)
        updated_state = %{state | components: updated_components}

        Logger.debug(
          "Updated component #{component_type}.#{field} to #{inspect(value)} for entity #{state.entity_id}"
        )

        {:reply, :ok, updated_state}
    end
  end

  @impl true
  def handle_call({:get_component, component_type}, _from, state) do
    component = Map.get(state.components, component_type)
    {:reply, component, state}
  end

  @impl true
  def handle_call({:has_component?, component_type}, _from, state) do
    has_component = Map.has_key?(state.components, component_type)
    {:reply, has_component, state}
  end

  @impl true
  def handle_call({:remove_component, component_type}, _from, state) do
    updated_components = Map.delete(state.components, component_type)
    updated_state = %{state | components: updated_components}

    # Update registry with removed component
    registry_name = state.registry_name
    registry_name.update_metadata(state.entity_id, :components, Map.keys(updated_components))

    Logger.debug("Removed component #{component_type} from entity #{state.entity_id}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:get_position, _from, state) do
    {:reply, state.position, state}
  end

  @impl true
  def handle_call({:set_position, zone, room, coordinates}, _from, state) do
    new_position = %{
      zone: zone,
      room: room,
      coordinates: coordinates
    }

    updated_state = %{state | position: new_position}

    # Update registry with new position
    registry_name = state.registry_name
    registry_name.update_metadata(state.entity_id, :zone, zone)
    registry_name.update_metadata(state.entity_id, :room, room)

    Logger.debug("Entity #{state.entity_id} moved to #{zone}:#{room}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state.status, state}
  end

  @impl true
  def handle_call({:set_status, status}, _from, state) do
    updated_state = %{state | status: status}

    # Update registry with new status
    registry_name = state.registry_name
    registry_name.update_metadata(state.entity_id, :status, status)

    Logger.debug("Entity #{state.entity_id} status changed to #{status}")
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_cast({:world_tick, tick_data}, state) do
    # Process world tick for this entity
    updated_state = process_tick_components(state, tick_data)
    updated_state = %{updated_state | last_tick: tick_data.tick_number}

    {:noreply, updated_state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Entity #{state.entity_id} terminating: #{inspect(reason)}")

    # Unregister from registry
    registry_name = state.registry_name
    registry_name.unregister(state.entity_id)

    :ok
  end

  # Private Functions

  defp process_tick_components(state, tick_data) do
    # Process components that need tick updates
    Enum.reduce(state.components, state, fn {component_type, component_data}, acc ->
      case process_component_tick(component_type, component_data, tick_data) do
        {:ok, updated_component} ->
          %{acc | components: Map.put(acc.components, component_type, updated_component)}

        :no_change ->
          acc
      end
    end)
  end

  defp process_component_tick(:health, component, _tick_data) do
    # Health regeneration logic
    if component.current < component.max do
      regen_amount = min(component.regen_rate, component.max - component.current)
      updated_component = %{component | current: component.current + regen_amount}
      {:ok, updated_component}
    else
      :no_change
    end
  end

  defp process_component_tick(:mana, component, _tick_data) do
    # Mana regeneration logic
    if component.current < component.max do
      regen_amount = min(component.regen_rate, component.max - component.current)
      updated_component = %{component | current: component.current + regen_amount}
      {:ok, updated_component}
    else
      :no_change
    end
  end

  defp process_component_tick(:stamina, component, _tick_data) do
    # Stamina regeneration logic
    if component.current < component.max do
      regen_amount = min(component.regen_rate, component.max - component.current)
      updated_component = %{component | current: component.current + regen_amount}
      {:ok, updated_component}
    else
      :no_change
    end
  end

  defp process_component_tick(_component_type, _component, _tick_data) do
    # Default: no change for unknown components
    :no_change
  end
end
