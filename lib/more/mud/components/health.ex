defmodule More.Mud.Components.Health do
  @moduledoc """
  Health component for entities.

  Provides:
  - Current and maximum health values
  - Regeneration rate per world tick
  - Health modification functions
  - Health status checking
  """

  @type t :: %__MODULE__{
          current: non_neg_integer(),
          max: non_neg_integer(),
          regen_rate: non_neg_integer(),
          last_regen: DateTime.t() | nil
        }

  defstruct current: 100, max: 100, regen_rate: 5, last_regen: nil

  @doc """
  Creates a new health component with the given values.
  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  @doc """
  Creates a health component with default values for the given level.
  """
  def new_for_level(level) do
    base_health = 50 + level * 25
    regen_rate = max(1, div(level, 5) + 2)

    new(
      current: base_health,
      max: base_health,
      regen_rate: regen_rate
    )
  end

  @doc """
  Applies damage to the health component.
  Returns the updated component and the actual damage dealt.
  """
  def take_damage(health, damage) do
    actual_damage = min(health.current, damage)
    new_current = max(0, health.current - actual_damage)

    updated_health = %{health | current: new_current}
    {updated_health, actual_damage}
  end

  @doc """
  Heals the health component.
  Returns the updated component and the actual healing done.
  """
  def heal(health, healing) do
    actual_healing = min(health.max - health.current, healing)
    new_current = min(health.max, health.current + actual_healing)

    updated_health = %{health | current: new_current}
    {updated_health, actual_healing}
  end

  @doc """
  Processes regeneration for a world tick.
  Returns the updated component and any regeneration that occurred.
  """
  def process_regen(health, _tick_data) do
    if health.current < health.max do
      regen_amount = min(health.regen_rate, health.max - health.current)
      new_current = health.current + regen_amount

      updated_health = %{health | current: new_current, last_regen: DateTime.utc_now()}

      {updated_health, regen_amount}
    else
      {health, 0}
    end
  end

  @doc """
  Checks if the entity is alive (has health > 0).
  """
  def alive?(health) do
    health.current > 0
  end

  @doc """
  Checks if the entity is at full health.
  """
  def full_health?(health) do
    health.current >= health.max
  end

  @doc """
  Gets the health percentage (0.0 to 1.0).
  """
  def health_percentage(health) do
    if health.max > 0 do
      health.current / health.max
    else
      0.0
    end
  end

  @doc """
  Gets the health percentage as a string (e.g., "75%").
  """
  def health_percentage_string(health) do
    percentage = health_percentage(health)
    "#{round(percentage * 100)}%"
  end

  @doc """
  Gets a health bar representation.
  """
  def health_bar(health, width \\ 20) do
    percentage = health_percentage(health)
    filled_width = round(percentage * width)
    empty_width = width - filled_width

    filled = String.duplicate("█", filled_width)
    empty = String.duplicate("░", empty_width)

    "[#{filled}#{empty}] #{health.current}/#{health.max}"
  end

  @doc """
  Sets the maximum health and adjusts current health proportionally.
  """
  def set_max_health(health, new_max) when new_max > 0 do
    if health.max > 0 do
      # Maintain the same percentage of health
      percentage = health.current / health.max
      new_current = round(percentage * new_max)

      %{health | current: new_current, max: new_max}
    else
      %{health | current: new_max, max: new_max}
    end
  end

  @doc """
  Increases the maximum health by the given amount.
  """
  def increase_max_health(health, amount) when amount > 0 do
    new_max = health.max + amount
    new_current = health.current + amount

    %{health | current: new_current, max: new_max}
  end

  @doc """
  Decreases the maximum health by the given amount.
  """
  def decrease_max_health(health, amount) when amount > 0 do
    new_max = max(1, health.max - amount)
    new_current = min(health.current, new_max)

    %{health | current: new_current, max: new_max}
  end
end
