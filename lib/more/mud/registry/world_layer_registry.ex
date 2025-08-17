defmodule More.Mud.Registry.WorldLayerRegistry do
  @moduledoc """
  Registry for tracking all world layer servers.

  This registry provides:
  - Fast lookup of layer servers by name and zone
  - Centralized tracking of all active layers
  - Easy discovery of layer capabilities
  """

  use GenServer
  require Logger

  @doc """
  Starts the world layer registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a world layer server.
  """
  def register(layer_name, zone_name, pid, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register, layer_name, zone_name, pid, metadata})
  end

  @doc """
  Unregisters a world layer server.
  """
  def unregister(layer_name, zone_name, pid) do
    GenServer.call(__MODULE__, {:unregister, layer_name, zone_name, pid})
  end

  @doc """
  Looks up a world layer server by name and zone.
  """
  def lookup(layer_name, zone_name) do
    GenServer.call(__MODULE__, {:lookup, layer_name, zone_name})
  end

  @doc """
  Gets all registered layer servers.
  """
  def all_layers do
    GenServer.call(__MODULE__, :all_layers)
  end

  @doc """
  Gets all layers for a specific zone.
  """
  def layers_for_zone(zone_name) do
    GenServer.call(__MODULE__, {:layers_for_zone, zone_name})
  end

  @doc """
  Gets all zones for a specific layer type.
  """
  def zones_for_layer(layer_name) do
    GenServer.call(__MODULE__, {:zones_for_layer, layer_name})
  end

  @doc """
  Gets all active layer servers.
  """
  def active_layers do
    GenServer.call(__MODULE__, :active_layers)
  end

  @doc """
  Counts the total number of registered layers.
  """
  def count do
    GenServer.call(__MODULE__, :count)
  end

  @doc """
  Counts the number of layers for a specific zone.
  """
  def count_for_zone(zone_name) do
    GenServer.call(__MODULE__, {:count_for_zone, zone_name})
  end

  @doc """
  Counts the number of zones for a specific layer type.
  """
  def count_for_layer(layer_name) do
    GenServer.call(__MODULE__, {:count_for_layer, layer_name})
  end

  @doc """
  Checks if a specific layer and zone combination is registered.
  """
  def registered?(layer_name, zone_name) do
    case lookup(layer_name, zone_name) do
      [] -> false
      _ -> true
    end
  end

  @doc """
  Gets metadata for a specific layer.
  """
  def get_metadata(layer_name, zone_name) do
    case lookup(layer_name, zone_name) do
      [{_pid, metadata}] -> metadata
      [] -> nil
    end
  end

  @doc """
  Updates metadata for a specific layer.
  """
  def update_metadata(layer_name, zone_name, pid, new_metadata) do
    GenServer.call(__MODULE__, {:update_metadata, layer_name, zone_name, pid, new_metadata})
  end

  @doc """
  Broadcasts a message to all layer servers.
  """
  def broadcast(message) do
    GenServer.cast(__MODULE__, {:broadcast, message})
  end

  @doc """
  Broadcasts a message to all layers of a specific type.
  """
  def broadcast_to_layer(layer_name, message) do
    GenServer.cast(__MODULE__, {:broadcast_to_layer, layer_name, message})
  end

  @doc """
  Broadcasts a message to all layers in a specific zone.
  """
  def broadcast_to_zone(zone_name, message) do
    GenServer.cast(__MODULE__, {:broadcast_to_zone, zone_name, message})
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    # Create ETS tables for fast lookups
    :ets.new(:world_layer_registry, [:set, :public, :named_table])
    :ets.new(:world_layer_by_zone, [:set, :public, :named_table])
    :ets.new(:world_layer_by_type, [:set, :public, :named_table])

    Logger.info("World layer registry started")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, layer_name, zone_name, pid, metadata}, _from, state) do
    # Store in main registry
    :ets.insert(:world_layer_registry, {{layer_name, zone_name}, pid, metadata})

    # Store in zone index
    :ets.insert(:world_layer_by_zone, {zone_name, layer_name, pid, metadata})

    # Store in layer type index
    :ets.insert(:world_layer_by_type, {layer_name, zone_name, pid, metadata})

    Logger.debug("Registered layer #{layer_name} for zone #{zone_name}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:unregister, layer_name, zone_name, pid}, _from, state) do
    # Remove from all tables
    :ets.delete(:world_layer_registry, {layer_name, zone_name})

    # Remove from zone index (match any metadata)
    :ets.match_delete(:world_layer_by_zone, {zone_name, layer_name, pid, :_})

    # Remove from layer type index (match any metadata)
    :ets.match_delete(:world_layer_by_type, {layer_name, zone_name, pid, :_})

    Logger.debug("Unregistered layer #{layer_name} for zone #{zone_name}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:lookup, layer_name, zone_name}, _from, state) do
    case :ets.lookup(:world_layer_registry, {layer_name, zone_name}) do
      [{_key, pid, metadata}] -> {:reply, [{pid, metadata}], state}
      [] -> {:reply, [], state}
    end
  end

  @impl true
  def handle_call(:all_layers, _from, state) do
    layers =
      :ets.tab2list(:world_layer_registry)
      |> Enum.map(fn {key, pid, metadata} -> {key, pid, metadata} end)

    {:reply, layers, state}
  end

  @impl true
  def handle_call({:layers_for_zone, zone_name}, _from, state) do
    layers =
      :ets.lookup(:world_layer_by_zone, zone_name)
      |> Enum.map(fn {_zone, layer_name, pid, metadata} ->
        {{layer_name, zone_name}, pid, metadata}
      end)

    {:reply, layers, state}
  end

  @impl true
  def handle_call({:zones_for_layer, layer_name}, _from, state) do
    zones =
      :ets.lookup(:world_layer_by_type, layer_name)
      |> Enum.map(fn {_layer, zone_name, pid, metadata} ->
        {{layer_name, zone_name}, pid, metadata}
      end)

    {:reply, zones, state}
  end

  @impl true
  def handle_call(:active_layers, _from, state) do
    layers =
      :ets.tab2list(:world_layer_registry)
      |> Enum.filter(fn {_key, pid, _metadata} -> Process.alive?(pid) end)
      |> Enum.map(fn {key, pid, metadata} -> {key, pid, metadata} end)

    {:reply, layers, state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    count = :ets.info(:world_layer_registry, :size)
    {:reply, count, state}
  end

  @impl true
  def handle_call({:count_for_zone, zone_name}, _from, state) do
    count = :ets.select_count(:world_layer_by_zone, [{{zone_name, :_, :_, :_}, [], [true]}])
    {:reply, count, state}
  end

  @impl true
  def handle_call({:count_for_layer, layer_name}, _from, state) do
    count = :ets.select_count(:world_layer_by_type, [{{layer_name, :_, :_, :_}, [], [true]}])
    {:reply, count, state}
  end

  @impl true
  def handle_call({:update_metadata, layer_name, zone_name, pid, new_metadata}, _from, state) do
    # Update metadata in all tables
    :ets.insert(:world_layer_registry, {{layer_name, zone_name}, pid, new_metadata})
    :ets.insert(:world_layer_by_zone, {zone_name, layer_name, pid, new_metadata})
    :ets.insert(:world_layer_by_type, {layer_name, zone_name, pid, new_metadata})

    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:broadcast, message}, state) do
    :ets.tab2list(:world_layer_registry)
    |> Enum.each(fn {_key, pid, _metadata} ->
      if Process.alive?(pid) do
        send(pid, message)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast_to_layer, layer_name, message}, state) do
    :ets.lookup(:world_layer_by_type, layer_name)
    |> Enum.each(fn {_layer, _zone, pid, _metadata} ->
      if Process.alive?(pid) do
        send(pid, message)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast_to_zone, zone_name, message}, state) do
    :ets.lookup(:world_layer_by_zone, zone_name)
    |> Enum.each(fn {_zone, _layer, pid, _metadata} ->
      if Process.alive?(pid) do
        send(pid, message)
      end
    end)

    {:noreply, state}
  end
end
