defmodule MoreWeb.GameLive.Panes.PlayerStatus do
  use MoreWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       player_name: "Unknown Player",
       level: 1,
       experience: 0,
       experience_to_next: 100,
       status: %{
         health: %{current: 100, max: 100, regen_rate: 5},
         mana: %{current: 100, max: 100, regen_rate: 3},
         stamina: %{current: 100, max: 100, regen_rate: 8}
       },
       effects: [],
       last_update: DateTime.utc_now()
     )}
  end

  @impl true
  def update(%{id: id} = assigns, socket) do
    {:ok,
     assign(socket,
       id: id,
       player_name: assigns[:player_name] || socket.assigns.player_name,
       level: assigns[:level] || socket.assigns.level,
       experience: assigns[:experience] || socket.assigns.experience,
       experience_to_next: assigns[:experience_to_next] || socket.assigns.experience_to_next,
       status: assigns[:status] || socket.assigns.status,
       effects: assigns[:effects] || socket.assigns.effects,
       last_update: assigns[:last_update] || socket.assigns.last_update
     )}
  end

  @impl true
  def update(%{world_tick: _tick_data}, socket) do
    # Handle world tick updates - could update regeneration
    {:ok, socket}
  end

  @impl true
  def update(%{player_status: status_data}, socket) do
    # Update player status from game world
    status = Map.merge(socket.assigns.status, status_data)
    {:ok, assign(socket, status: status, last_update: DateTime.utc_now())}
  end

  @impl true
  def update(%{player_effect: effect_data}, socket) do
    # Add or update player effect
    effects = update_player_effects(socket.assigns.effects, effect_data)
    {:ok, assign(socket, effects: effects)}
  end

  @impl true
  def update(%{level_up: level_data}, socket) do
    # Handle level up
    {:ok,
     assign(socket,
       level: level_data.new_level,
       experience: level_data.new_experience,
       experience_to_next: level_data.next_level_experience
     )}
  end

  @impl true
  def handle_event("toggle_status_details", _params, socket) do
    # This could toggle detailed status view
    {:noreply, socket}
  end

  @impl true
  def handle_event("show_effects", _params, socket) do
    # This could show detailed effects
    {:noreply, socket}
  end

  # Private functions

  defp update_player_effects(effects, effect_data) do
    case effect_data.action do
      :add ->
        [effect_data | effects]

      :remove ->
        Enum.reject(effects, &(&1.id == effect_data.id))

      :update ->
        Enum.map(effects, fn effect ->
          if effect.id == effect_data.id, do: Map.merge(effect, effect_data), else: effect
        end)
    end
  end

  defp get_status_percentage(current, max) do
    if max > 0, do: current / max * 100, else: 0
  end

  defp get_status_bar_class(percentage) do
    cond do
      percentage >= 80 -> "status-bar-high"
      percentage >= 50 -> "status-bar-medium"
      percentage >= 25 -> "status-bar-low"
      true -> "status-bar-critical"
    end
  end

  defp format_experience(exp, next_level_exp) do
    "#{exp}/#{next_level_exp}"
  end

  defp get_experience_percentage(exp, next_level_exp) do
    if next_level_exp > 0, do: exp / next_level_exp * 100, else: 0
  end
end
