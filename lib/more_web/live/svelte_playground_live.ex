defmodule MoreWeb.SveltePlaygroundLive do
  use MoreWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    # Initialize with some default components
    socket =
      socket
      |> assign(:active_components, [])
      |> assign(:available_components, [])
      |> assign(:build_status, "Idle")
      |> assign(:last_build_time, nil)
      |> assign(:memory_usage, "Unknown")

    # Load available components from registry
    available_components = MoreWeb.SvelteComponentRegistry.list_components()
    socket = assign(socket, :available_components, available_components)

    # Get build status
    build_status = MoreWeb.SvelteComponentRegistry.get_build_status()

    socket =
      socket
      |> assign(:build_status, build_status.build_status)
      |> assign(:last_build_time, build_status.last_build_time)

    if Mix.env() == :dev do
      # In development, check for component updates periodically
      send_update_after(__MODULE__, :check_components, 5000)
    end

    {:ok, socket}
  end

  def handle_event("add_component", %{"component" => component_name}, socket) do
    # Create a new component instance
    component_id = generate_component_id()

    new_component = %{
      id: component_id,
      name: component_name,
      type: component_name,
      props: get_default_props(component_name),
      created_at: DateTime.utc_now()
    }

    active_components = [new_component | socket.assigns.active_components]
    socket = assign(socket, :active_components, active_components)

    # Trigger build if component doesn't exist
    if !component_exists?(component_name) do
      MoreWeb.SvelteComponentRegistry.trigger_build(component_name)
    end

    Logger.info("Added component: #{component_name} with ID: #{component_id}")
    {:noreply, socket}
  end

  def handle_event("remove_component", %{"id" => component_id}, socket) do
    active_components =
      Enum.reject(socket.assigns.active_components, fn c -> c.id == component_id end)

    socket = assign(socket, :active_components, active_components)

    Logger.info("Removed component with ID: #{component_id}")
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
      send_update_after(__MODULE__, :check_components, 5000)
    end

    {:noreply, socket}
  end

  def handle_info({:update_memory_usage}, socket) do
    # Simulate memory usage update
    memory_usage = "#{Enum.random(10..100)}MB"
    socket = assign(socket, :memory_usage, memory_usage)

    # Continue updating
    send_update_after(__MODULE__, :update_memory_usage, 10000)
    {:noreply, socket}
  end

  # Private functions

  defp generate_component_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end

  defp component_exists?(component_name) do
    MoreWeb.SvelteComponentRegistry.get_component(component_name) != nil
  end

  defp get_default_props("hello-world") do
    %{message: "Hello from Svelte Island!", color: "blue"}
  end

  defp get_default_props("counter") do
    %{initial_value: 0, step: 1}
  end

  defp get_default_props("3d-cube") do
    %{size: 1.0, color: "#ff6b6b", rotation_speed: 0.01}
  end

  defp get_default_props(_) do
    %{}
  end
end
