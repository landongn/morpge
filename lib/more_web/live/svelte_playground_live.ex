defmodule MoreWeb.SveltePlaygroundLive do
  use MoreWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_components, [])
      |> assign(:available_components, [])
      |> assign(:build_status, "Idle")
      |> assign(:last_build_time, nil)
      |> assign(:memory_usage, "Unknown")

    available_components = MoreWeb.SvelteComponentRegistry.list_components()
    socket = assign(socket, :available_components, available_components)

    build_status = MoreWeb.SvelteComponentRegistry.get_build_status()

    socket =
      socket
      |> assign(:build_status, build_status.build_status)
      |> assign(:last_build_time, build_status.last_build_time)

    if Mix.env() == :dev do
      Process.send_after(self(), {:check_components}, 5000)
    end

    Process.send_after(self(), {:update_memory_usage}, 10000)

    {:ok, socket}
  end

  def handle_event("add_component", %{"component" => component_type}, socket) do
    # Create a new component instance with positioning
    component_id = generate_component_id()

    # Calculate default position based on component type
    position = get_default_position(component_type, socket.assigns.active_components)
    size = get_default_size(component_type)
    z_index = get_next_z_index(socket.assigns.active_components)

    new_component = %{
      id: component_id,
      name: component_type,
      type: component_type,
      position: position,
      size: size,
      z_index: z_index,
      props: get_default_props(component_type),
      created_at: DateTime.utc_now()
    }

    active_components = [new_component | socket.assigns.active_components]
    socket = assign(socket, :active_components, active_components)

    # Trigger build if component doesn't exist
    if !component_exists?(component_type) do
      MoreWeb.SvelteComponentRegistry.trigger_build(component_type)
    end

    Logger.info("Added component: #{component_type} at position #{inspect(position)}")
    {:noreply, socket}
  end

  def handle_event("remove_component", %{"id" => component_id}, socket) do
    active_components =
      Enum.reject(socket.assigns.active_components, fn c -> c.id == component_id end)

    socket = assign(socket, :active_components, active_components)

    Logger.info("Removed component with ID: #{component_id}")
    {:noreply, socket}
  end

  def handle_event("move_component", %{"id" => component_id, "direction" => direction}, socket) do
    active_components =
      Enum.map(socket.assigns.active_components, fn component ->
        if component.id == component_id do
          case direction do
            "up" -> %{component | z_index: component.z_index + 1}
            "down" -> %{component | z_index: max(1, component.z_index - 1)}
            _ -> component
          end
        else
          component
        end
      end)

    socket = assign(socket, :active_components, active_components)
    Logger.info("Moved component #{component_id} #{direction}")
    {:noreply, socket}
  end

  def handle_event(
        "update_component_position",
        %{"id" => component_id, "position" => position},
        socket
      ) do
    active_components =
      Enum.map(socket.assigns.active_components, fn component ->
        if component.id == component_id do
          %{component | position: position}
        else
          component
        end
      end)

    socket = assign(socket, :active_components, active_components)
    Logger.info("Updated component #{component_id} position to #{inspect(position)}")
    {:noreply, socket}
  end

  def handle_event("update_component_size", %{"id" => component_id, "size" => size}, socket) do
    active_components =
      Enum.map(socket.assigns.active_components, fn component ->
        if component.id == component_id do
          %{component | size: size}
        else
          component
        end
      end)

    socket = assign(socket, :active_components, active_components)
    Logger.info("Updated component #{component_id} size to #{inspect(size)}")
    {:noreply, socket}
  end

  def handle_event("clear_components", _params, socket) do
    socket = assign(socket, :active_components, [])
    Logger.info("Cleared all components")
    {:noreply, socket}
  end

  def handle_info({:check_components}, socket) do
    # Check for component updates
    available_components = MoreWeb.SvelteComponentRegistry.list_components()
    build_status = MoreWeb.SvelteComponentRegistry.get_build_status()

    socket =
      socket
      |> assign(:available_components, available_components)
      |> assign(:build_status, build_status.build_status)
      |> assign(:last_build_time, build_status.last_build_time)

    # Continue checking in development
    if Mix.env() == :dev do
      Process.send_after(self(), {:check_components}, 5000)
    end

    {:noreply, socket}
  end

  def handle_info({:update_memory_usage}, socket) do
    # Simulate memory usage update
    memory_usage = "#{Enum.random(10..100)}MB"
    socket = assign(socket, :memory_usage, memory_usage)

    # Continue updating
    Process.send_after(self(), {:update_memory_usage}, 10000)

    {:noreply, socket}
  end

  # Private functions

  defp generate_component_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end

  defp component_exists?(component_type) do
    # Check if component exists in registry
    case MoreWeb.SvelteComponentRegistry.get_component(component_type) do
      nil -> false
      _ -> true
    end
  end

  defp get_default_position(component_type, existing_components) do
    # Calculate position to avoid overlapping
    base_positions = %{
      # Full screen positioning
      "world-scene" => %{x: 0, y: 0},
      "world-chat" => %{x: 50, y: 600},
      "local-chat" => %{x: 400, y: 600},
      "system-chat" => %{x: 750, y: 600},
      "player-status" => %{x: 1100, y: 100},
      "command-input" => %{x: 50, y: 750}
    }

    base_position = Map.get(base_positions, component_type, %{x: 100, y: 100})

    # Check for overlaps and adjust
    adjusted_position = adjust_position_for_overlap(base_position, existing_components)

    adjusted_position
  end

  defp adjust_position_for_overlap(position, existing_components) do
    # Special handling for world-scene (full screen)
    if position.x == 0 && position.y == 0 do
      position
    else
      # Simple overlap detection - move component down and right if needed
      overlap_found =
        Enum.any?(existing_components, fn component ->
          abs(component.position.x - position.x) < 200 &&
            abs(component.position.y - position.y) < 150
        end)

      if overlap_found do
        %{x: position.x + 50, y: position.y + 50}
      else
        position
      end
    end
  end

  defp get_default_size(component_type) do
    case component_type do
      # Full screen size
      "world-scene" -> %{width: 1920, height: 1080}
      "world-chat" -> %{width: 300, height: 200}
      "local-chat" -> %{width: 300, height: 200}
      "system-chat" -> %{width: 300, height: 200}
      "player-status" -> %{width: 250, height: 300}
      "command-input" -> %{width: 800, height: 100}
      _ -> %{width: 300, height: 200}
    end
  end

  defp get_next_z_index(existing_components) do
    case existing_components do
      [] ->
        1

      components ->
        max_z = Enum.max_by(components, & &1.z_index, fn -> 0 end).z_index
        max_z + 1
    end
  end

  defp get_default_props(component_type) do
    case component_type do
      "world-scene" ->
        %{
          cameraPosition: %{x: 10, y: 15, z: 10},
          cameraTarget: %{x: 0, y: 0, z: 0},
          showGrid: true,
          showAxes: true,
          enableControls: true
        }

      "world-chat" ->
        %{
          channel: "world",
          maxMessages: 100,
          autoScroll: true
        }

      "local-chat" ->
        %{
          channel: "local",
          maxMessages: 50,
          autoScroll: true
        }

      "system-chat" ->
        %{
          channel: "system",
          maxMessages: 50,
          autoScroll: true
        }

      "player-status" ->
        %{
          health: 100,
          maxHealth: 100,
          mana: 50,
          maxMana: 100,
          stamina: 75,
          maxStamina: 100
        }

      "command-input" ->
        %{
          maxHistory: 20,
          placeholder: "Enter command..."
        }

      _ ->
        %{}
    end
  end
end
