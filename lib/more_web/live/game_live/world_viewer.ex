defmodule MoreWeb.GameLive.WorldViewer do
  @moduledoc """
  LiveView component for viewing and interacting with the world layers.

  This component provides:
  - Top-down 2D tile-based view of the world
  - Layer selection and visibility toggles
  - Real-time updates from the world system
  - Player position tracking
  - Interactive map editing capabilities
  """

  use Phoenix.LiveView
  require Logger

  alias More.Mud.World.WorldManager
  alias More.Mud.World.WorldLayerServer

  @impl true
  def mount(_params, _session, socket) do
    # Initialize with default values
    socket =
      assign(socket, %{
        zone_name: "starting_village",
        player_x: 10,
        player_y: 10,
        view_width: 15,
        view_height: 15,
        selected_layer: "all",
        visible_layers: ["ground", "atmosphere", "plants", "structures", "floor_plans", "doors"],
        world_data: %{},
        editing_mode: false,
        selected_tile: nil,
        tile_palette: %{
          "ground" => [".", "~", "^", "#"],
          "atmosphere" => [" ", "f", "r", "s"],
          "plants" => [" ", "t", "b", "f", "g"],
          "structures" => [" ", "H", "S", "T", "W", "C"],
          "floor_plans" => [" ", "r", "h", "s", "c"],
          "doors" => [" ", "D", "G", "P", "T"]
        }
      })

    # Start periodic updates
    if connected?(socket) do
      :timer.send_interval(1000, self(), :update_world)
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("select_layer", %{"layer" => layer}, socket) do
    socket = assign(socket, selected_layer: layer)
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_layer_visibility", %{"layer" => layer}, socket) do
    visible_layers = socket.assigns.visible_layers

    updated_layers =
      if layer in visible_layers do
        List.delete(visible_layers, layer)
      else
        [layer | visible_layers]
      end

    socket = assign(socket, visible_layers: updated_layers)
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_player", %{"direction" => direction}, socket) do
    {new_x, new_y} =
      calculate_new_position(socket.assigns.player_x, socket.assigns.player_y, direction)

    # Check if the new position is valid
    if is_valid_position?(socket, new_x, new_y) do
      socket = assign(socket, player_x: new_x, player_y: new_y)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_editing", _params, socket) do
    editing_mode = !socket.assigns.editing_mode
    socket = assign(socket, editing_mode: editing_mode)
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_tile", %{"layer" => layer, "tile" => tile}, socket) do
    socket = assign(socket, selected_tile: {layer, tile})
    {:noreply, socket}
  end

  @impl true
  def handle_event("place_tile", %{"x" => x, "y" => y}, socket) do
    case socket.assigns.selected_tile do
      {layer, tile} when layer != "all" ->
        # Place the tile on the specified layer
        case WorldLayerServer.set_at(
               layer,
               socket.assigns.zone_name,
               String.to_integer(x),
               String.to_integer(y),
               tile
             ) do
          :ok ->
            # Refresh world data
            send(self(), :update_world)
            {:noreply, socket}

          {:error, reason} ->
            Logger.error("Failed to place tile: #{inspect(reason)}")
            {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("zoom_in", _params, socket) do
    view_width = max(5, socket.assigns.view_width - 2)
    view_height = max(5, socket.assigns.view_height - 2)
    socket = assign(socket, view_width: view_width, view_height: view_height)
    {:noreply, socket}
  end

  @impl true
  def handle_event("zoom_out", _params, socket) do
    view_width = min(30, socket.assigns.view_width + 2)
    view_height = min(30, socket.assigns.view_height + 2)
    socket = assign(socket, view_width: view_width, view_height: view_height)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_world, socket) do
    # Get the current world data for the visible region
    world_data = get_world_region_data(socket.assigns)
    socket = assign(socket, world_data: world_data)
    {:noreply, socket}
  end

  # Private Functions

  defp calculate_new_position(x, y, direction) do
    case direction do
      "north" -> {x, y - 1}
      "south" -> {x, y + 1}
      "east" -> {x + 1, y}
      "west" -> {x - 1, y}
      "northeast" -> {x + 1, y - 1}
      "northwest" -> {x - 1, y - 1}
      "southeast" -> {x + 1, y + 1}
      "southwest" -> {x - 1, y + 1}
      _ -> {x, y}
    end
  end

  defp is_valid_position?(_socket, x, y) do
    # Basic bounds checking
    x >= 0 and y >= 0 and x < 20 and y < 20
  end

  defp get_world_region_data(assigns) do
    # Calculate the region to display based on player position and view size
    start_x = max(0, assigns.player_x - div(assigns.view_width, 2))
    start_y = max(0, assigns.player_y - div(assigns.view_height, 2))

    # Get the region data from the world manager
    case WorldManager.get_region_view(
           assigns.zone_name,
           start_x,
           start_y,
           assigns.view_width,
           assigns.view_height
         ) do
      {:ok, region_data} -> region_data
      _ -> %{}
    end
  end

  # These functions were removed due to LiveView template restrictions
  # Tile rendering is now handled directly in the template
end
