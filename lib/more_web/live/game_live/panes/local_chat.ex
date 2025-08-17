defmodule MoreWeb.GameLive.Panes.LocalChat do
  use MoreWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       messages: [],
       auto_scroll: true,
       message_count: 0,
       room_name: "Unknown Room"
     )}
  end

  @impl true
  def update(%{id: id} = assigns, socket) do
    {:ok,
     assign(socket,
       id: id,
       messages: assigns[:messages] || socket.assigns.messages,
       auto_scroll: assigns[:auto_scroll] || socket.assigns.auto_scroll,
       message_count: assigns[:message_count] || socket.assigns.message_count,
       room_name: assigns[:room_name] || socket.assigns.room_name
     )}
  end

  @impl true
  def update(%{world_tick: _tick_data}, socket) do
    # Handle world tick updates
    {:ok, socket}
  end

  @impl true
  def update(%{entity_action: action_data}, socket) do
    # Add entity action to local chat
    message = %{
      id: generate_message_id(),
      content: "#{action_data.entity} #{action_data.action}",
      timestamp: DateTime.utc_now(),
      type: :local,
      priority: :normal
    }

    messages = [message | socket.assigns.messages]
    message_count = socket.assigns.message_count + 1

    # Keep only last 100 messages
    messages = if length(messages) > 100, do: Enum.take(messages, 100), else: messages

    {:ok, assign(socket, messages: messages, message_count: message_count)}
  end

  @impl true
  def update(%{room_message: message_data}, socket) do
    # Add room-specific message
    message = %{
      id: generate_message_id(),
      content: message_data.content,
      timestamp: DateTime.utc_now(),
      type: :local,
      priority: message_data.priority || :normal
    }

    messages = [message | socket.assigns.messages]
    message_count = socket.assigns.message_count + 1

    # Keep only last 100 messages
    messages = if length(messages) > 100, do: Enum.take(messages, 100), else: messages

    {:ok, assign(socket, messages: messages, message_count: message_count)}
  end

  @impl true
  def update(%{room_change: room_data}, socket) do
    # Update room information
    {:ok, assign(socket, room_name: room_data.name)}
  end

  @impl true
  def handle_event("toggle_auto_scroll", _params, socket) do
    {:noreply, assign(socket, auto_scroll: !socket.assigns.auto_scroll)}
  end

  @impl true
  def handle_event("clear_messages", _params, socket) do
    {:noreply, assign(socket, messages: [], message_count: 0)}
  end

  @impl true
  def handle_event("scroll_to_top", _params, socket) do
    # This will be handled by JavaScript hook
    {:noreply, socket}
  end

  @impl true
  def handle_event("scroll_to_bottom", _params, socket) do
    # This will be handled by JavaScript hook
    {:noreply, socket}
  end

  # Private functions

  defp generate_message_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp get_message_class(message) do
    base_class = "message local-message"

    priority_class =
      case message.priority do
        :critical -> " priority-critical"
        :high -> " priority-high"
        :normal -> ""
        :low -> " priority-low"
      end

    base_class <> priority_class
  end
end
