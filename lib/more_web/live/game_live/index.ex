defmodule MoreWeb.GameLive.Index do
  use MoreWeb, :live_view
  require Logger

  # These will be used when integrating with the entity system
  # alias More.Mud.Registry.EntityRegistry
  # alias More.Mud.Entities.Entity

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
       # Chat state
       world_messages: [],
       local_messages: [],
       system_messages: [],

       # Game state
       current_room: nil,
       visible_entities: [],
       player_status: %{
         health: %{current: 100, max: 100},
         mana: %{current: 100, max: 100},
         stamina: %{current: 100, max: 100}
       },

       # UI state
       active_channel: :local,
       command_input: "",
       chat_scroll_positions: %{
         world: 0,
         local: 0,
         system: 0
       }
     )}
  end

  @impl true
  def handle_event("send_command", %{"command" => command}, socket) do
    case process_command(command, socket) do
      {:ok, response} ->
        # Add response to appropriate channel
        socket = add_message_to_channel(socket, :local, response)
        {:noreply, socket}

      {:error, error_msg} ->
        # Add error to system channel
        socket = add_message_to_channel(socket, :system, error_msg)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("switch_channel", %{"channel" => channel}, socket) do
    channel_atom = String.to_existing_atom(channel)
    {:noreply, assign(socket, active_channel: channel_atom)}
  end

  @impl true
  def handle_event("clear_command", _params, socket) do
    {:noreply, assign(socket, command_input: "")}
  end

  @impl true
  def handle_event("update_command", %{"command" => value}, socket) do
    {:noreply, assign(socket, command_input: value)}
  end

  @impl true
  def handle_event("show_world_viewer", _params, socket) do
    # TODO: Implement world viewer display
    socket = add_message_to_channel(socket, :system, "World viewer coming soon!")
    {:noreply, socket}
  end

  @impl true
  def handle_info({:world_tick, tick_data}, socket) do
    # Process world tick updates
    socket = process_world_tick(socket, tick_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:entity_action, action_data}, socket) do
    # Process entity actions
    socket = process_entity_action(socket, action_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:combat_event, combat_data}, socket) do
    # Process combat events
    socket = process_combat_event(socket, combat_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:system_message, message_data}, socket) do
    # Process system messages
    socket = add_message_to_channel(socket, :system, message_data)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_status, status_data}, socket) do
    # Update player status
    {:noreply, assign(socket, player_status: status_data)}
  end

  # Private functions

  defp process_command(command, socket) do
    command = String.trim(command)

    case parse_command(command) do
      {:look, target} ->
        handle_look_command(socket, target)

      {:move, direction} ->
        handle_move_command(socket, direction)

      {:say, message} ->
        handle_say_command(socket, message)

      {:help, topic} ->
        handle_help_command(socket, topic)

      {:unknown, cmd} ->
        {:error, "Unknown command: #{cmd}. Type 'help' for available commands."}
    end
  end

  defp parse_command(command) do
    cond do
      command == "look" or command == "l" ->
        {:look, nil}

      command == "help" or command == "h" ->
        {:help, nil}

      String.starts_with?(command, "look ") ->
        target = String.slice(command, 5..-1//-1)
        {:look, target}

      String.starts_with?(command, "move ") ->
        direction = String.slice(command, 5..-1//-1)
        {:move, direction}

      String.starts_with?(command, "say ") ->
        message = String.slice(command, 4..-1//-1)
        {:say, message}

      String.starts_with?(command, "help ") ->
        topic = String.slice(command, 5..-1//-1)
        {:help, topic}

      true ->
        {:unknown, command}
    end
  end

  defp handle_look_command(_socket, target) do
    if target do
      # Look at specific target
      {:ok, "You see #{target}."}
    else
      # Look at current room
      {:ok, "You are in a featureless room. There are exits to the north and east."}
    end
  end

  defp handle_move_command(_socket, direction) do
    valid_directions = ["north", "south", "east", "west", "up", "down"]

    if direction in valid_directions do
      {:ok, "You move #{direction}."}
    else
      {:error, "Invalid direction. Valid directions are: #{Enum.join(valid_directions, ", ")}"}
    end
  end

  defp handle_say_command(_socket, message) do
    {:ok, "You say: #{message}"}
  end

  defp handle_help_command(_socket, topic) do
    help_text =
      case topic do
        "movement" ->
          "Movement commands: move <direction> or just <direction>\n" <>
            "Valid directions: north, south, east, west, up, down"

        "combat" ->
          "Combat commands: attack <target>, cast <spell> <target>\n" <>
            "Use 'look' to see what's around you."

        "social" ->
          "Social commands: say <message>, tell <player> <message>\n" <>
            "Use 'who' to see other players online."

        _ ->
          "Available commands:\n" <>
            "- look: Examine your surroundings or a specific target\n" <>
            "- move <direction>: Move in the specified direction\n" <>
            "- say <message>: Speak in the local channel\n" <>
            "- help <topic>: Get help on a specific topic\n" <>
            "Type 'help <topic>' for more detailed information."
      end

    {:ok, help_text}
  end

  defp add_message_to_channel(socket, channel, content) do
    message = %{
      id: generate_message_id(),
      content: content,
      timestamp: DateTime.utc_now(),
      type: channel
    }

    case channel do
      :world ->
        assign(socket, world_messages: [message | socket.assigns.world_messages])

      :local ->
        assign(socket, local_messages: [message | socket.assigns.local_messages])

      :system ->
        assign(socket, system_messages: [message | socket.assigns.system_messages])
    end
  end

  defp process_world_tick(socket, _tick_data) do
    # Update player status based on world tick
    # This would integrate with the entity system
    socket
  end

  defp process_entity_action(socket, action_data) do
    # Add entity action to local channel
    message = "#{action_data.entity} #{action_data.action}"
    add_message_to_channel(socket, :local, message)
  end

  defp process_combat_event(socket, combat_data) do
    # Add combat event to system channel
    message =
      "#{combat_data.attacker} attacks #{combat_data.target} for #{combat_data.damage} damage!"

    add_message_to_channel(socket, :system, message)
  end

  defp generate_message_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  # This function will be used when implementing channel-specific message filtering
  # defp get_channel_messages(socket, channel) do
  #   case channel do
  #     :world -> socket.assigns.world_messages
  #     :local -> socket.assigns.local_messages
  #     :system -> socket.assigns.system_messages
  #   end
  # end

  defp get_channel_title(channel) do
    case channel do
      :world -> "World Channel"
      :local -> "Local Channel"
      :system -> "System Channel"
    end
  end

  defp get_channel_class(channel, active_channel) do
    base_class = "chat-box"
    if channel == active_channel, do: "#{base_class} active", else: base_class
  end
end
