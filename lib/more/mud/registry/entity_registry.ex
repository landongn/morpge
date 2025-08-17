defmodule More.Mud.Registry.EntityRegistry do
  @moduledoc """
  Central registry for all entities in the game world.

  Provides:
  - Fast entity lookup by various criteria
  - Centralized entity lifecycle management
  - Smart indexing for performance
  - Entity metadata tracking
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts the Entity Registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a new entity in the registry.
  """
  def register(entity_id, entity_pid, metadata) do
    GenServer.call(__MODULE__, {:register, entity_id, entity_pid, metadata})
  end

  @doc """
  Unregisters an entity from the registry.
  """
  def unregister(entity_id) do
    GenServer.call(__MODULE__, {:unregister, entity_id})
  end

  @doc """
  Gets the PID of an entity by ID.
  """
  def get_pid(entity_id) do
    GenServer.call(__MODULE__, {:get_pid, entity_id})
  end

  @doc """
  Gets all entities of a specific type.
  """
  def get_entities_by_type(entity_type) do
    GenServer.call(__MODULE__, {:get_entities_by_type, entity_type})
  end

  @doc """
  Gets all entities in a specific zone.
  """
  def get_entities_in_zone(zone) do
    GenServer.call(__MODULE__, {:get_entities_in_zone, zone})
  end

  @doc """
  Gets all entities in a specific room.
  """
  def get_entities_in_room(room) do
    GenServer.call(__MODULE__, {:get_entities_in_room, room})
  end

  @doc """
  Gets all entities with a specific component.
  """
  def get_entities_with_component(component_type) do
    GenServer.call(__MODULE__, {:get_entities_with_component, component_type})
  end

  @doc """
  Updates entity metadata.
  """
  def update_metadata(entity_id, field, value) do
    GenServer.call(__MODULE__, {:update_metadata, entity_id, field, value})
  end

  @doc """
  Gets entity metadata.
  """
  def get_metadata(entity_id) do
    GenServer.call(__MODULE__, {:get_metadata, entity_id})
  end

  @doc """
  Gets the total count of entities.
  """
  def get_entity_count do
    GenServer.call(__MODULE__, :get_entity_count)
  end

  @doc """
  Gets statistics about the registry.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting Entity Registry")

    initial_state = %{
      entities: %{},
      indexes: %{
        by_type: %{},
        by_zone: %{},
        by_room: %{},
        by_component: %{}
      },
      stats: %{
        total_entities: 0,
        by_type: %{},
        by_zone: %{},
        by_room: %{}
      }
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:register, entity_id, entity_pid, metadata}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        # New entity registration
        entity_data = %{
          pid: entity_pid,
          type: metadata.type,
          zone: Map.get(metadata, :zone),
          room: Map.get(metadata, :room),
          components: Map.get(metadata, :components, []),
          status: Map.get(metadata, :status, :active),
          last_seen: DateTime.utc_now(),
          metadata: metadata
        }

        updated_entities = Map.put(state.entities, entity_id, entity_data)
        updated_indexes = update_indexes(state.indexes, entity_id, entity_data)
        updated_stats = update_stats(state.stats, entity_data, :add)

        updated_state = %{
          state
          | entities: updated_entities,
            indexes: updated_indexes,
            stats: updated_stats
        }

        Logger.info("Registered entity #{entity_id} of type #{metadata.type}")
        {:reply, :ok, updated_state}

      _existing ->
        # Entity already exists, update it
        {:reply, {:error, :entity_already_exists}, state}
    end
  end

  @impl true
  def handle_call({:unregister, entity_id}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :entity_not_found}, state}

      entity_data ->
        # Remove from entities
        updated_entities = Map.delete(state.entities, entity_id)

        # Remove from indexes
        updated_indexes = remove_from_indexes(state.indexes, entity_id, entity_data)

        # Update stats
        updated_stats = update_stats(state.stats, entity_data, :remove)

        updated_state = %{
          state
          | entities: updated_entities,
            indexes: updated_indexes,
            stats: updated_stats
        }

        Logger.info("Unregistered entity #{entity_id}")
        {:reply, :ok, updated_state}
    end
  end

  @impl true
  def handle_call({:get_pid, entity_id}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil -> {:reply, nil, state}
      entity_data -> {:reply, entity_data.pid, state}
    end
  end

  @impl true
  def handle_call({:get_entities_by_type, entity_type}, _from, state) do
    entity_ids = Map.get(state.indexes.by_type, entity_type, [])
    entities = Enum.map(entity_ids, fn id -> {id, Map.get(state.entities, id)} end)
    {:reply, entities, state}
  end

  @impl true
  def handle_call({:get_entities_in_zone, zone}, _from, state) do
    entity_ids = Map.get(state.indexes.by_zone, zone, [])
    entities = Enum.map(entity_ids, fn id -> {id, Map.get(state.entities, id)} end)
    {:reply, entities, state}
  end

  @impl true
  def handle_call({:get_entities_in_room, room}, _from, state) do
    entity_ids = Map.get(state.indexes.by_room, room, [])
    entities = Enum.map(entity_ids, fn id -> {id, Map.get(state.entities, id)} end)
    {:reply, entities, state}
  end

  @impl true
  def handle_call({:get_entities_with_component, component_type}, _from, state) do
    entity_ids = Map.get(state.indexes.by_component, component_type, [])
    entities = Enum.map(entity_ids, fn id -> {id, Map.get(state.entities, id)} end)
    {:reply, entities, state}
  end

  @impl true
  def handle_call({:update_metadata, entity_id, field, value}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil ->
        {:reply, {:error, :entity_not_found}, state}

      entity_data ->
        # Update the entity data
        updated_entity_data = update_entity_field(entity_data, field, value)
        updated_entities = Map.put(state.entities, entity_id, updated_entity_data)

        # Update indexes if needed
        updated_indexes =
          update_indexes_for_field_change(
            state.indexes,
            entity_id,
            entity_data,
            updated_entity_data,
            field
          )

        updated_state = %{state | entities: updated_entities, indexes: updated_indexes}

        Logger.debug("Updated metadata for entity #{entity_id}: #{field} = #{inspect(value)}")
        {:reply, :ok, updated_state}
    end
  end

  @impl true
  def handle_call({:get_metadata, entity_id}, _from, state) do
    case Map.get(state.entities, entity_id) do
      nil -> {:reply, nil, state}
      entity_data -> {:reply, entity_data, state}
    end
  end

  @impl true
  def handle_call(:get_entity_count, _from, state) do
    {:reply, state.stats.total_entities, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, state.stats, state}
  end

  # Private Functions

  defp update_indexes(indexes, entity_id, entity_data) do
    # Update type index
    by_type = Map.update(indexes.by_type, entity_data.type, [entity_id], &[entity_id | &1])

    # Update zone index
    by_zone =
      if entity_data.zone do
        Map.update(indexes.by_zone, entity_data.zone, [entity_id], &[entity_id | &1])
      else
        indexes.by_zone
      end

    # Update room index
    by_room =
      if entity_data.room do
        Map.update(indexes.by_room, entity_data.room, [entity_id], &[entity_id | &1])
      else
        indexes.by_room
      end

    # Update component index
    by_component =
      Enum.reduce(entity_data.components, indexes.by_component, fn component, acc ->
        Map.update(acc, component, [entity_id], &[entity_id | &1])
      end)

    %{indexes | by_type: by_type, by_zone: by_zone, by_room: by_room, by_component: by_component}
  end

  defp remove_from_indexes(indexes, entity_id, entity_data) do
    # Remove from type index
    by_type = Map.update(indexes.by_type, entity_data.type, [], &List.delete(&1, entity_id))

    # Remove from zone index
    by_zone =
      if entity_data.zone do
        Map.update(indexes.by_zone, entity_data.zone, [], &List.delete(&1, entity_id))
      else
        indexes.by_zone
      end

    # Remove from room index
    by_room =
      if entity_data.room do
        Map.update(indexes.by_room, entity_data.room, [], &List.delete(&1, entity_id))
      else
        indexes.by_room
      end

    # Remove from component index
    by_component =
      Enum.reduce(entity_data.components, indexes.by_component, fn component, acc ->
        Map.update(acc, component, [], &List.delete(&1, entity_id))
      end)

    %{indexes | by_type: by_type, by_zone: by_zone, by_room: by_room, by_component: by_component}
  end

  defp update_stats(stats, entity_data, operation) do
    total_entities =
      case operation do
        :add -> stats.total_entities + 1
        :remove -> stats.total_entities - 1
      end

    by_type =
      Map.update(stats.by_type, entity_data.type, 1, fn count ->
        case operation do
          :add -> count + 1
          :remove -> max(0, count - 1)
        end
      end)

    by_zone =
      if entity_data.zone do
        Map.update(stats.by_zone, entity_data.zone, 1, fn count ->
          case operation do
            :add -> count + 1
            :remove -> max(0, count - 1)
          end
        end)
      else
        stats.by_zone
      end

    by_room =
      if entity_data.room do
        Map.update(stats.by_room, entity_data.room, 1, fn count ->
          case operation do
            :add -> count + 1
            :remove -> max(0, count - 1)
          end
        end)
      else
        stats.by_room
      end

    %{
      stats
      | total_entities: total_entities,
        by_type: by_type,
        by_zone: by_zone,
        by_room: by_room
    }
  end

  defp update_entity_field(entity_data, field, value) do
    case field do
      :type -> %{entity_data | type: value}
      :zone -> %{entity_data | zone: value}
      :room -> %{entity_data | room: value}
      :components -> %{entity_data | components: value}
      :status -> %{entity_data | status: value}
      :last_seen -> %{entity_data | last_seen: DateTime.utc_now()}
      _ -> entity_data
    end
  end

  defp update_indexes_for_field_change(indexes, entity_id, old_data, new_data, field) do
    case field do
      :zone ->
        # Remove from old zone, add to new zone
        by_zone =
          if old_data.zone do
            Map.update(indexes.by_zone, old_data.zone, [], &List.delete(&1, entity_id))
          else
            indexes.by_zone
          end

        by_zone =
          if new_data.zone do
            Map.update(by_zone, new_data.zone, [entity_id], &[entity_id | &1])
          else
            by_zone
          end

        %{indexes | by_zone: by_zone}

      :room ->
        # Remove from old room, add to new room
        by_room =
          if old_data.room do
            Map.update(indexes.by_room, old_data.room, [], &List.delete(&1, entity_id))
          else
            indexes.by_room
          end

        by_room =
          if new_data.room do
            Map.update(by_room, new_data.room, [entity_id], &[entity_id | &1])
          else
            by_room
          end

        %{indexes | by_room: by_room}

      :components ->
        # Remove from old components, add to new components
        old_components = MapSet.new(old_data.components)
        new_components = MapSet.new(new_data.components)

        removed_components = MapSet.difference(old_components, new_components)
        added_components = MapSet.difference(new_components, old_components)

        # Remove from old components
        by_component =
          Enum.reduce(removed_components, indexes.by_component, fn component, acc ->
            Map.update(acc, component, [], &List.delete(&1, entity_id))
          end)

        # Add to new components
        by_component =
          Enum.reduce(added_components, by_component, fn component, acc ->
            Map.update(acc, component, [entity_id], &[entity_id | &1])
          end)

        %{indexes | by_component: by_component}

      _ ->
        indexes
    end
  end
end
