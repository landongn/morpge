defmodule MoreWeb.GameLive.Surface do
  use MoreWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to world events
      Phoenix.PubSub.subscribe(More.PubSub, "world_events")

      if socket.assigns.current_scope do
        Phoenix.PubSub.subscribe(More.PubSub, "player_#{socket.assigns.current_scope.user.id}")
      end
    end

    {:ok,
     assign(socket,
       # Surface state
       surface_id: generate_surface_id(),

       # Pane configuration
       panes: %{
         "world_chat" => %{
           id: "world_chat",
           type: :chat,
           title: "World Channel",
           position: %{x: 0, y: 0, width: 300, height: 200},
           component: "world_chat",
           visible: true,
           z_index: 1
         },
         "local_chat" => %{
           id: "local_chat",
           type: :chat,
           title: "Local Channel",
           position: %{x: 320, y: 0, width: 300, height: 200},
           component: "local_chat",
           visible: true,
           z_index: 1
         },
         "system_chat" => %{
           id: "system_chat",
           type: :chat,
           title: "System Channel",
           position: %{x: 640, y: 0, width: 300, height: 200},
           component: "system_chat",
           visible: true,
           z_index: 1
         },
         "command_input" => %{
           id: "command_input",
           type: :input,
           title: "Command Input",
           position: %{x: 0, y: 220, width: 940, height: 60},
           component: "command_input",
           visible: true,
           z_index: 2
         },
         "player_status" => %{
           id: "player_status",
           type: :status,
           title: "Player Status",
           position: %{x: 0, y: 300, width: 300, height: 120},
           component: "player_status",
           visible: true,
           z_index: 1
         }
       },

       # Active pane for interaction
       active_pane: nil,

       # Surface background state
       background: %{
         type: :solid,
         color: "#1a1a1a",
         image: nil,
         effects: []
       },

       # UI state
       show_pane_controls: false,
       show_pane_list: false
     )}
  end

  @impl true
  def handle_event("toggle_pane_controls", _params, socket) do
    {:noreply, assign(socket, show_pane_controls: !socket.assigns.show_pane_controls)}
  end

  @impl true
  def handle_event("toggle_pane_list", _params, socket) do
    {:noreply, assign(socket, show_pane_list: !socket.assigns.show_pane_list)}
  end

  @impl true
  def handle_event("set_active_pane", %{"pane_id" => pane_id}, socket) do
    {:noreply, assign(socket, active_pane: pane_id)}
  end

  @impl true
  def handle_event("move_pane", %{"pane_id" => pane_id, "x" => x, "y" => y}, socket) do
    panes =
      Map.update!(socket.assigns.panes, pane_id, fn pane ->
        %{
          pane
          | position:
              Map.merge(pane.position, %{x: String.to_integer(x), y: String.to_integer(y)})
        }
      end)

    {:noreply, assign(socket, panes: panes)}
  end

  @impl true
  def handle_event(
        "resize_pane",
        %{"pane_id" => pane_id, "width" => width, "height" => height},
        socket
      ) do
    panes =
      Map.update!(socket.assigns.panes, pane_id, fn pane ->
        %{
          pane
          | position:
              Map.merge(pane.position, %{
                width: width,
                height: height
              })
        }
      end)

    {:noreply, assign(socket, panes: panes)}
  end

  @impl true
  def handle_event("toggle_pane_visibility", %{"pane_id" => pane_id}, socket) do
    panes =
      Map.update!(socket.assigns.panes, pane_id, fn pane ->
        %{pane | visible: !pane.visible}
      end)

    {:noreply, assign(socket, panes: panes)}
  end

  @impl true
  def handle_event("add_pane", %{"pane_config" => pane_config}, socket) do
    pane_id = generate_pane_id()

    new_pane = %{
      id: pane_id,
      type: String.to_existing_atom(pane_config["type"]),
      title: pane_config["title"],
      position: %{
        x: String.to_integer(pane_config["x"]),
        y: String.to_integer(pane_config["y"]),
        width: String.to_integer(pane_config["width"]),
        height: String.to_integer(pane_config["height"])
      },
      component: pane_config["component"],
      visible: true,
      z_index: 1
    }

    panes = Map.put(socket.assigns.panes, pane_id, new_pane)
    {:noreply, assign(socket, panes: panes)}
  end

  @impl true
  def handle_event("remove_pane", %{"pane_id" => pane_id}, socket) do
    panes = Map.delete(socket.assigns.panes, pane_id)

    active_pane =
      if socket.assigns.active_pane == pane_id, do: nil, else: socket.assigns.active_pane

    {:noreply, assign(socket, panes: panes, active_pane: active_pane)}
  end

  @impl true
  def handle_event("set_background", %{"background" => background_json}, socket) do
    case Jason.decode(background_json) do
      {:ok, background} ->
        {:noreply, assign(socket, background: background)}

      {:error, _} ->
        # Fallback to default background if JSON parsing fails
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:world_tick, tick_data}, socket) do
    # Broadcast world tick to all panes
    Enum.each(socket.assigns.panes, fn {pane_id, _pane} ->
      send_update("MoreWeb.GameLive.Panes.#{String.upcase(pane_id)}",
        id: pane_id,
        world_tick: tick_data
      )
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:entity_action, action_data}, socket) do
    # Broadcast entity action to relevant panes
    Enum.each(socket.assigns.panes, fn {pane_id, pane} ->
      if pane.type == :chat do
        send_update("MoreWeb.GameLive.Panes.#{String.upcase(pane_id)}",
          id: pane_id,
          entity_action: action_data
        )
      end
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:combat_event, combat_data}, socket) do
    # Broadcast combat event to system chat pane
    if Map.has_key?(socket.assigns.panes, "system_chat") do
      send_update("MoreWeb.GameLive.Panes.SystemChat",
        id: "system_chat",
        combat_event: combat_data
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:system_message, message_data}, socket) do
    # Broadcast system message to system chat pane
    if Map.has_key?(socket.assigns.panes, "system_chat") do
      send_update("MoreWeb.GameLive.Panes.SystemChat",
        id: "system_chat",
        system_message: message_data
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_status, status_data}, socket) do
    # Update player status pane
    if Map.has_key?(socket.assigns.panes, "player_status") do
      send_update("MoreWeb.GameLive.Panes.PlayerStatus",
        id: "player_status",
        player_status: status_data
      )
    end

    {:noreply, socket}
  end

  # Private functions

  defp generate_surface_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp generate_pane_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end

  # These functions are used in the HEEx template for dynamic component loading
  defp get_pane_component("world_chat"), do: "MoreWeb.GameLive.Panes.WorldChat"
  defp get_pane_component("local_chat"), do: "MoreWeb.GameLive.Panes.LocalChat"
  defp get_pane_component("system_chat"), do: "MoreWeb.GameLive.Panes.DefaultPane"
  defp get_pane_component("command_input"), do: "MoreWeb.GameLive.Panes.DefaultPane"
  defp get_pane_component("player_status"), do: "MoreWeb.GameLive.Panes.DefaultPane"
  defp get_pane_component(_), do: "MoreWeb.GameLive.Panes.DefaultPane"

  defp get_background_style(background) do
    case Map.get(background, "type") do
      "solid" ->
        color = Map.get(background, "color", "#1a1a1a")
        "background-color: #{color};"

      "image" ->
        image = Map.get(background, "image")

        if image do
          "background-image: url('#{image}'); background-size: cover; background-position: center;"
        else
          "background-color: #1a1a1a;"
        end

      "gradient" ->
        gradient = Map.get(background, "gradient")

        if gradient do
          "background: #{gradient};"
        else
          "background-color: #1a1a1a;"
        end

      _ ->
        "background-color: #1a1a1a;"
    end
  end
end
