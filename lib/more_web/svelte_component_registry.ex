defmodule MoreWeb.SvelteComponentRegistry do
  use GenServer
  require Logger

  @registry_name __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @registry_name)
  end

  def init(_) do
    # Initialize with default components
    initial_state = %{
      components: %{
        "hello-world" => %{
          id: "hw-001",
          name: "hello-world",
          status: "Available",
          data: %{message: "Hello from Svelte Island!", color: "blue"},
          created_at: DateTime.utc_now()
        },
        "counter" => %{
          id: "ctr-001", 
          name: "counter",
          status: "Available",
          data: %{initial_value: 0, step: 1},
          created_at: DateTime.utc_now()
        },
        "3d-cube" => %{
          id: "cube-001",
          name: "3d-cube", 
          status: "Available",
          data: %{size: 1.0, color: "#ff6b6b", rotation_speed: 0.01},
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
    Task.async(fn ->
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
