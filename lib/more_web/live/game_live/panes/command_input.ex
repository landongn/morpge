defmodule MoreWeb.GameLive.Panes.CommandInput do
  use MoreWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       command_input: "",
       command_history: [],
       history_index: -1,
       suggestions: []
     )}
  end

  @impl true
  def update(%{id: id} = assigns, socket) do
    {:ok,
     assign(socket,
       id: id,
       command_input: assigns[:command_input] || socket.assigns.command_input,
       command_history: assigns[:command_history] || socket.assigns.command_history,
       history_index: assigns[:history_index] || socket.assigns.history_index,
       suggestions: assigns[:suggestions] || socket.assigns.suggestions
     )}
  end

  @impl true
  def handle_event("update_command", %{"value" => value}, socket) do
    {:noreply, assign(socket, command_input: value)}
  end

  @impl true
  def handle_event("send_command", _params, socket) do
    command = socket.assigns.command_input |> String.trim()

    if command != "" do
      # Add to history
      history = [command | socket.assigns.command_history]
      history = if length(history) > 50, do: Enum.take(history, 50), else: history

      # Send command to parent LiveView
      send(self(), {:command_sent, command})

      {:noreply,
       assign(socket,
         command_input: "",
         command_history: history,
         history_index: -1
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_command", _params, socket) do
    {:noreply, assign(socket, command_input: "")}
  end

  @impl true
  def handle_event("navigate_history", %{"direction" => direction}, socket) do
    {history_index, command_input} =
      case direction do
        "up" ->
          navigate_history_up(socket.assigns.command_history, socket.assigns.history_index)

        "down" ->
          navigate_history_down(socket.assigns.command_history, socket.assigns.history_index)

        _ ->
          {socket.assigns.history_index, socket.assigns.command_input}
      end

    {:noreply, assign(socket, history_index: history_index, command_input: command_input)}
  end

  @impl true
  def handle_event("show_suggestions", _params, socket) do
    suggestions = generate_suggestions(socket.assigns.command_input)
    {:noreply, assign(socket, suggestions: suggestions)}
  end

  @impl true
  def handle_event("hide_suggestions", _params, socket) do
    {:noreply, assign(socket, suggestions: [])}
  end

  @impl true
  def handle_event("select_suggestion", %{"suggestion" => suggestion}, socket) do
    {:noreply, assign(socket, command_input: suggestion, suggestions: [])}
  end

  # Private functions

  defp navigate_history_up(history, current_index) do
    if current_index < length(history) - 1 do
      new_index = current_index + 1
      {new_index, Enum.at(history, new_index)}
    else
      {current_index, ""}
    end
  end

  defp navigate_history_down(history, current_index) do
    if current_index > -1 do
      new_index = current_index - 1
      command = if new_index >= 0, do: Enum.at(history, new_index), else: ""
      {new_index, command}
    else
      {current_index, ""}
    end
  end

  defp generate_suggestions(input) do
    base_commands = [
      "look",
      "l",
      "move",
      "say",
      "tell",
      "help",
      "h",
      "attack",
      "cast",
      "use",
      "get",
      "drop",
      "inventory",
      "i",
      "who",
      "where",
      "status",
      "quit",
      "save"
    ]

    if input == "" do
      base_commands
    else
      base_commands
      |> Enum.filter(&String.starts_with?(&1, String.downcase(input)))
      |> Enum.take(5)
    end
  end
end
