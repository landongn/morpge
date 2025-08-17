defmodule More.Mud.Components.HealthTest do
  use ExUnit.Case, async: true
  alias More.Mud.Components.Health

  describe "health creation" do
    test "creates health component with default values" do
      health = Health.new()

      assert health.current == 100
      assert health.max == 100
      assert health.regen_rate == 5
      assert health.last_regen == nil
    end

    test "creates health component with custom values" do
      health = Health.new(current: 75, max: 150, regen_rate: 10)

      assert health.current == 75
      assert health.max == 150
      assert health.regen_rate == 10
    end

    test "creates health component for specific level" do
      level_1_health = Health.new_for_level(1)
      level_5_health = Health.new_for_level(5)
      level_10_health = Health.new_for_level(10)

      # Level 1: 50 + (1 * 25) = 75 health, regen = max(1, 0 + 2) = 2
      assert level_1_health.current == 75
      assert level_1_health.max == 75
      assert level_1_health.regen_rate == 2

      # Level 5: 50 + (5 * 25) = 175 health, regen = max(1, 1 + 2) = 3
      assert level_5_health.current == 175
      assert level_5_health.max == 175
      assert level_5_health.regen_rate == 3

      # Level 10: 50 + (10 * 25) = 300 health, regen = max(1, 2 + 2) = 4
      assert level_10_health.current == 300
      assert level_10_health.max == 300
      assert level_10_health.regen_rate == 4
    end
  end

  describe "damage and healing" do
    test "can take damage" do
      health = Health.new(current: 100, max: 100)

      {updated_health, damage_dealt} = Health.take_damage(health, 25)

      assert updated_health.current == 75
      assert damage_dealt == 25
    end

    test "damage is capped at current health" do
      health = Health.new(current: 50, max: 100)

      {updated_health, damage_dealt} = Health.take_damage(health, 100)

      assert updated_health.current == 0
      # Only 50 damage dealt, not 100
      assert damage_dealt == 50
    end

    test "can heal" do
      health = Health.new(current: 50, max: 100)

      {updated_health, healing_done} = Health.heal(health, 30)

      assert updated_health.current == 80
      assert healing_done == 30
    end

    test "healing is capped at maximum health" do
      health = Health.new(current: 80, max: 100)

      {updated_health, healing_done} = Health.heal(health, 50)

      assert updated_health.current == 100
      # Only 20 healing done, not 50
      assert healing_done == 20
    end

    test "cannot heal beyond maximum health" do
      health = Health.new(current: 100, max: 100)

      {updated_health, healing_done} = Health.heal(health, 25)

      assert updated_health.current == 100
      assert healing_done == 0
    end
  end

  describe "regeneration" do
    test "processes regeneration correctly" do
      health = Health.new(current: 80, max: 100, regen_rate: 15)

      {updated_health, regen_amount} = Health.process_regen(health, %{tick_number: 1})

      # 80 + 15
      assert updated_health.current == 95
      assert regen_amount == 15
      assert updated_health.last_regen != nil
    end

    test "regeneration is capped at maximum health" do
      health = Health.new(current: 90, max: 100, regen_rate: 15)

      {updated_health, regen_amount} = Health.process_regen(health, %{tick_number: 1})

      assert updated_health.current == 100
      # Only 10 regeneration, not 15
      assert regen_amount == 10
    end

    test "no regeneration when at full health" do
      health = Health.new(current: 100, max: 100, regen_rate: 15)

      {updated_health, regen_amount} = Health.process_regen(health, %{tick_number: 1})

      assert updated_health.current == 100
      assert regen_amount == 0
    end

    test "regeneration updates last_regen timestamp" do
      health = Health.new(current: 80, max: 100, regen_rate: 15)
      original_last_regen = health.last_regen

      {updated_health, _regen_amount} = Health.process_regen(health, %{tick_number: 1})

      assert updated_health.last_regen != original_last_regen
      assert is_struct(updated_health.last_regen, DateTime)
    end
  end

  describe "health status checks" do
    test "checks if entity is alive" do
      full_health = Health.new(current: 100, max: 100)
      partial_health = Health.new(current: 50, max: 100)
      no_health = Health.new(current: 0, max: 100)

      assert Health.alive?(full_health)
      assert Health.alive?(partial_health)
      refute Health.alive?(no_health)
    end

    test "checks if entity is at full health" do
      full_health = Health.new(current: 100, max: 100)
      partial_health = Health.new(current: 50, max: 100)
      over_health = Health.new(current: 150, max: 100)

      assert Health.full_health?(full_health)
      refute Health.full_health?(partial_health)
      # Current >= max
      assert Health.full_health?(over_health)
    end

    test "calculates health percentage" do
      full_health = Health.new(current: 100, max: 100)
      half_health = Health.new(current: 50, max: 100)
      quarter_health = Health.new(current: 25, max: 100)
      no_health = Health.new(current: 0, max: 100)

      assert Health.health_percentage(full_health) == 1.0
      assert Health.health_percentage(half_health) == 0.5
      assert Health.health_percentage(quarter_health) == 0.25
      assert Health.health_percentage(no_health) == 0.0
    end

    test "handles zero maximum health gracefully" do
      zero_health = Health.new(current: 0, max: 0)

      assert Health.health_percentage(zero_health) == 0.0
    end
  end

  describe "health display" do
    test "generates health percentage string" do
      full_health = Health.new(current: 100, max: 100)
      half_health = Health.new(current: 50, max: 100)
      quarter_health = Health.new(current: 25, max: 100)

      assert Health.health_percentage_string(full_health) == "100%"
      assert Health.health_percentage_string(half_health) == "50%"
      assert Health.health_percentage_string(quarter_health) == "25%"
    end

    test "generates health bar" do
      full_health = Health.new(current: 100, max: 100)
      half_health = Health.new(current: 50, max: 100)
      quarter_health = Health.new(current: 25, max: 100)

      # Test with default width (20)
      full_bar = Health.health_bar(full_health)
      half_bar = Health.health_bar(half_health)
      quarter_bar = Health.health_bar(quarter_health)

      assert full_bar =~ "[████████████████████] 100/100"
      assert half_bar =~ "[██████████░░░░░░░░░░] 50/100"
      assert quarter_bar =~ "[█████░░░░░░░░░░░░░░░] 25/100"
    end

    test "generates health bar with custom width" do
      health = Health.new(current: 75, max: 100)

      # Test with width 10
      bar = Health.health_bar(health, 10)

      assert bar =~ "[████████░░] 75/100"
    end
  end

  describe "health modification" do
    test "sets maximum health and adjusts current proportionally" do
      # 75%
      health = Health.new(current: 75, max: 100)

      updated_health = Health.set_max_health(health, 200)

      assert updated_health.max == 200
      # 75% of 200
      assert updated_health.current == 150
    end

    test "sets maximum health when current is zero" do
      health = Health.new(current: 0, max: 0)

      updated_health = Health.set_max_health(health, 100)

      assert updated_health.max == 100
      assert updated_health.current == 100
    end

    test "increases maximum health" do
      health = Health.new(current: 80, max: 100)

      updated_health = Health.increase_max_health(health, 50)

      assert updated_health.max == 150
      # 80 + 50
      assert updated_health.current == 130
    end

    test "decreases maximum health" do
      health = Health.new(current: 80, max: 100)

      updated_health = Health.decrease_max_health(health, 30)

      assert updated_health.max == 70
      # Capped at new max
      assert updated_health.current == 70
    end

    test "decreases maximum health with current health adjustment" do
      health = Health.new(current: 50, max: 100)

      updated_health = Health.decrease_max_health(health, 30)

      assert updated_health.max == 70
      # Current stays the same
      assert updated_health.current == 50
    end

    test "prevents maximum health from going below 1" do
      health = Health.new(current: 100, max: 100)

      updated_health = Health.decrease_max_health(health, 200)

      assert updated_health.max == 1
      assert updated_health.current == 1
    end
  end
end
