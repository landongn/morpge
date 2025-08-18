defmodule MoreWeb.SvelteComponentRegistry do
  use GenServer
  require Logger

  @registry_name __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @registry_name)
  end

  def init(_) do
    initial_state = %{
      components: %{
        "world-scene" => %{
          id: "world-001",
          name: "world-scene",
          status: "Available",
          data: %{
            cameraPosition: %{x: 10, y: 15, z: 10},
            cameraTarget: %{x: 0, y: 0, z: 0},
            showGrid: true,
            showAxes: true,
            enableControls: true
          },
          created_at: DateTime.utc_now()
        },
        "world-chat" => %{
          id: "world-chat-001",
          name: "world-chat",
          status: "Available",
          data: %{
            channel: "world",
            maxMessages: 100,
            autoScroll: true,
            messages: [
              %{
                id: 1,
                type: "system",
                content: "Welcome to More MUD!",
                timestamp: DateTime.utc_now()
              },
              %{
                id: 2,
                type: "player",
                author: "GM",
                content: "The world awaits your exploration.",
                timestamp: DateTime.utc_now()
              }
            ]
          },
          created_at: DateTime.utc_now()
        },
        "local-chat" => %{
          id: "local-chat-001",
          name: "local-chat",
          status: "Available",
          data: %{
            channel: "local",
            maxMessages: 50,
            autoScroll: true,
            messages: [
              %{id: 1, type: "system", content: "Local area chat", timestamp: DateTime.utc_now()}
            ]
          },
          created_at: DateTime.utc_now()
        },
        "system-chat" => %{
          id: "system-chat-001",
          name: "system-chat",
          status: "Available",
          data: %{
            channel: "system",
            maxMessages: 50,
            autoScroll: true,
            messages: [
              %{
                id: 1,
                type: "system",
                content: "System messages will appear here",
                timestamp: DateTime.utc_now()
              }
            ]
          },
          created_at: DateTime.utc_now()
        },
        "player-status" => %{
          id: "player-status-001",
          name: "player-status",
          status: "Available",
          data: %{
            health: 100,
            maxHealth: 100,
            mana: 50,
            maxMana: 100,
            stamina: 75,
            maxStamina: 100,
            level: 1,
            experience: 0,
            nextLevel: 100
          },
          created_at: DateTime.utc_now()
        },
        "command-input" => %{
          id: "command-input-001",
          name: "command-input",
          status: "Available",
          data: %{
            maxHistory: 20,
            placeholder: "Enter command...",
            commandHistory: [],
            currentCommand: ""
          },
          created_at: DateTime.utc_now()
        }
      },
      build_status: "Idle",
      last_build_time: nil,
      watchers: %{}
    }

    # Start watching for component changes in development
    if Mix.env() == :dev do
      start_component_watcher()
    end

    {:ok, initial_state}
  end

  # Public API

  def get_component(name) do
    GenServer.call(@registry_name, {:get_component, name})
  end

  def list_components do
    GenServer.call(@registry_name, {:list_components})
  end

  def get_build_status do
    GenServer.call(@registry_name, {:get_build_status})
  end

  def add_component(name, component_data) do
    GenServer.call(@registry_name, {:add_component, name, component_data})
  end

  def remove_component(name) do
    GenServer.call(@registry_name, {:remove_component, name})
  end

  def trigger_build(component_name) do
    GenServer.cast(@registry_name, {:trigger_build, component_name})
  end

  # Callbacks

  def handle_call({:get_component, name}, _from, state) do
    component = Map.get(state.components, name)
    {:reply, component, state}
  end

  def handle_call({:list_components}, _from, state) do
    components = Map.values(state.components)
    {:reply, components, state}
  end

  def handle_call({:get_build_status}, _from, state) do
    status = %{
      build_status: state.build_status,
      last_build_time: state.last_build_time
    }

    {:reply, status, state}
  end

  def handle_call({:add_component, name, component_data}, _from, state) do
    component = %{
      id: generate_id(),
      name: name,
      status: "Available",
      data: component_data,
      created_at: DateTime.utc_now()
    }

    new_components = Map.put(state.components, name, component)
    new_state = Map.put(state, :components, new_components)

    Logger.info("Added Svelte component: #{name}")
    {:reply, component, new_state}
  end

  def handle_call({:remove_component, name}, _from, state) do
    new_components = Map.delete(state.components, name)
    new_state = Map.put(state, :components, new_components)

    Logger.info("Removed Svelte component: #{name}")
    {:reply, :ok, new_state}
  end

  def handle_cast({:trigger_build, component_name}, state) do
    new_state = Map.put(state, :build_status, "Building #{component_name}")

    # Simulate build process
    Task.start(fn ->
      # Simulate build time
      Process.sleep(1000)
      GenServer.cast(@registry_name, {:build_completed, component_name})
    end)

    {:noreply, new_state}
  end

  def handle_cast({:build_completed, component_name}, state) do
    new_state =
      state
      |> Map.put(:build_status, "Idle")
      |> Map.put(:last_build_time, DateTime.utc_now())

    Logger.info("Build completed for component: #{component_name}")
    {:noreply, new_state}
  end

  def handle_info({:component_changed, path}, state) do
    component_name = extract_component_name(path)
    Logger.info("Component changed: #{component_name}")

    # Trigger rebuild
    trigger_build(component_name)

    {:noreply, state}
  end

  # Catch-all for unexpected messages (like Task references)
  def handle_info(msg, state) do
    Logger.debug("Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  # Private functions

  defp start_component_watcher do
    # In a real implementation, this would use FileSystem or similar
    # For now, we'll simulate it
    Logger.info("Starting Svelte component watcher")
  end

  defp extract_component_name(path) do
    path
    |> Path.basename()
    |> String.replace_suffix(".js", "")
    |> String.replace_suffix(".svelte", "")
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end
end
