defmodule MoreWeb.GameLive.Panes.SystemChat do
  use MoreWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       messages: [],
       auto_scroll: true,
       message_count: 0,
       filters: %{
         combat: true,
         system: true,
         debug: false,
         error: true
       }
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
       filters: assigns[:filters] || socket.assigns.filters
     )}
  end

  @impl true
  def update(%{world_tick: _tick_data}, socket) do
    # Handle world tick updates
    {:ok, socket}
  end

  @impl true
  def update(%{combat_event: combat_data}, socket) do
    # Add combat event to system chat
    message = %{
      id: generate_message_id(),
      content:
        "#{combat_data.attacker} attacks #{combat_data.target} for #{combat_data.damage} damage!",
      timestamp: DateTime.utc_now(),
      type: :combat,
      priority: :normal
    }

    messages = [message | socket.assigns.messages]
    message_count = socket.assigns.message_count + 1

    # Keep only last 100 messages
    messages = if length(messages) > 100, do: Enum.take(messages, 100), else: messages

    {:ok, assign(socket, messages: messages, message_count: message_count)}
  end

  @impl true
  def update(%{system_message: message_data}, socket) do
    # Add system message
    message = %{
      id: generate_message_id(),
      content: message_data.content,
      timestamp: DateTime.utc_now(),
      type: :system,
      priority: message_data.priority || :normal
    }

    messages = [message | socket.assigns.messages]
    message_count = socket.assigns.message_count + 1

    # Keep only last 100 messages
    messages = if length(messages) > 100, do: Enum.take(messages, 100), else: messages

    {:ok, assign(socket, messages: messages, message_count: message_count)}
  end

  @impl true
  def update(%{error_message: error_data}, socket) do
    # Add error message
    message = %{
      id: generate_message_id(),
      content: "ERROR: #{error_data.content}",
      timestamp: DateTime.utc_now(),
      type: :error,
      priority: :high
    }

    messages = [message | socket.assigns.messages]
    message_count = socket.assigns.message_count + 1

    # Keep only last 100 messages
    messages = if length(messages) > 100, do: Enum.take(messages, 100), else: messages

    {:ok, assign(socket, messages: messages, message_count: message_count)}
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

  @impl true
  def handle_event("toggle_filter", %{"filter" => filter}, socket) do
    filters = Map.update!(socket.assigns.filters, filter, &(!&1))
    {:noreply, assign(socket, filters: filters)}
  end

  # Private functions

  defp generate_message_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp get_message_class(message) do
    base_class = "message system-message"

    type_class =
      case message.type do
        :combat -> " message-combat"
        :system -> " message-system"
        :error -> " message-error"
        _ -> ""
      end

    priority_class =
      case message.priority do
        :critical -> " priority-critical"
        :high -> " priority-high"
        :normal -> ""
        :low -> " priority-low"
      end

    base_class <> type_class <> priority_class
  end

  defp should_show_message(message, filters) do
    case message.type do
      :combat -> filters.combat
      :system -> filters.system
      :error -> filters.error
      :debug -> filters.debug
      _ -> true
    end
  end

  defp get_filtered_messages(messages, filters) do
    Enum.filter(messages, &should_show_message(&1, filters))
  end
end
