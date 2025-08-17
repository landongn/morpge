defmodule More.Mud.Entities.EntityTest do
  use ExUnit.Case, async: false
  alias More.Mud.Entities.Entity

  setup do
    # Start the Entity Registry for testing
    start_supervised!(More.Mud.Registry.EntityRegistry)

    # Start a test entity
    {:ok, entity_pid} =
      Entity.start_link(
        entity_id: "test_entity_001",
        entity_type: :player,
        components: %{}
      )

    %{entity_pid: entity_pid}
  end

  describe "entity initialization" do
    test "starts with correct initial state", %{entity_pid: entity_pid} do
      state = Entity.get_state(entity_pid)

      assert state.entity_id == "test_entity_001"
      assert state.entity_type == :player
      assert state.status == :active
      assert state.components == %{}
      assert state.position.zone == nil
      assert state.position.room == nil
      assert is_struct(state.created_at, DateTime)
    end

    test "registers with entity registry on start" do
      # The entity should be registered in the registry
      metadata = More.Mud.Registry.EntityRegistry.get_metadata("test_entity_001")
      assert metadata != nil
      assert metadata.type == :player
      assert metadata.status == :active
    end
  end

  describe "component management" do
    test "can add components", %{entity_pid: entity_pid} do
      health_component = %{current: 100, max: 100, regen_rate: 5}

      assert :ok = Entity.add_component(entity_pid, :health, health_component)

      # Verify component was added
      assert Entity.has_component?(entity_pid, :health)
      assert Entity.get_component(entity_pid, :health) == health_component
    end

    test "can update component fields", %{entity_pid: entity_pid} do
      # Add a health component first
      health_component = %{current: 100, max: 100, regen_rate: 5}
      Entity.add_component(entity_pid, :health, health_component)

      # Update the current health
      assert :ok = Entity.update_component(entity_pid, :health, :current, 75)

      # Verify the update
      updated_health = Entity.get_component(entity_pid, :health)
      assert updated_health.current == 75
      assert updated_health.max == 100
    end

    test "can remove components", %{entity_pid: entity_pid} do
      # Add a component first
      health_component = %{current: 100, max: 100, regen_rate: 5}
      Entity.add_component(entity_pid, :health, health_component)

      # Verify it exists
      assert Entity.has_component?(entity_pid, :health)

      # Remove it
      assert :ok = Entity.remove_component(entity_pid, :health)

      # Verify it's gone
      refute Entity.has_component?(entity_pid, :health)
      assert Entity.get_component(entity_pid, :health) == nil
    end

    test "returns error when updating non-existent component", %{entity_pid: entity_pid} do
      result = Entity.update_component(entity_pid, :nonexistent, :field, :value)
      assert result == {:error, :component_not_found}
    end
  end

  describe "position management" do
    test "can set and get position", %{entity_pid: entity_pid} do
      # Set position
      assert :ok = Entity.set_position(entity_pid, "starting_zone", "room_001")

      # Get position
      position = Entity.get_position(entity_pid)
      assert position.zone == "starting_zone"
      assert position.room == "room_001"
      assert position.coordinates == nil
    end

    test "can set position with coordinates", %{entity_pid: entity_pid} do
      coordinates = %{x: 10, y: 20, z: 0}
      assert :ok = Entity.set_position(entity_pid, "zone_1", "room_1", coordinates)

      position = Entity.get_position(entity_pid)
      assert position.coordinates == coordinates
    end

    test "position updates are reflected in registry", %{entity_pid: entity_pid} do
      Entity.set_position(entity_pid, "test_zone", "test_room")

      # Check registry metadata
      metadata = More.Mud.Registry.EntityRegistry.get_metadata("test_entity_001")
      assert metadata.zone == "test_zone"
      assert metadata.room == "test_room"
    end
  end

  describe "status management" do
    test "can set and get status", %{entity_pid: entity_pid} do
      # Initial status should be :active
      assert Entity.get_status(entity_pid) == :active

      # Change status
      assert :ok = Entity.set_status(entity_pid, :inactive)
      assert Entity.get_status(entity_pid) == :inactive

      # Change back
      assert :ok = Entity.set_status(entity_pid, :active)
      assert Entity.get_status(entity_pid) == :active
    end

    test "status updates are reflected in registry", %{entity_pid: entity_pid} do
      Entity.set_status(entity_pid, :inactive)

      metadata = More.Mud.Registry.EntityRegistry.get_metadata("test_entity_001")
      assert metadata.status == :inactive
    end
  end

  describe "world tick processing" do
    test "processes world ticks", %{entity_pid: entity_pid} do
      # Add a health component that will regenerate
      health_component = %{current: 50, max: 100, regen_rate: 10}
      Entity.add_component(entity_pid, :health, health_component)

      # Process a world tick
      tick_data = %{tick_number: 1, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      # Health should have regenerated
      updated_health = Entity.get_component(entity_pid, :health)
      # 50 + 10
      assert updated_health.current == 60
    end

    test "tracks last tick", %{entity_pid: entity_pid} do
      tick_data = %{tick_number: 42, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      state = Entity.get_state(entity_pid)
      assert state.last_tick == 42
    end
  end

  describe "entity cleanup" do
    test "unregisters from registry on termination", %{entity_pid: entity_pid} do
      # Verify entity is registered
      assert More.Mud.Registry.EntityRegistry.get_metadata("test_entity_001") != nil

      # Stop the entity
      GenServer.stop(entity_pid)

      # Wait a bit for cleanup
      Process.sleep(10)

      # Verify entity is unregistered
      assert More.Mud.Registry.EntityRegistry.get_metadata("test_entity_001") == nil
    end
  end

  describe "health component integration" do
    test "health regeneration works correctly", %{entity_pid: entity_pid} do
      # Add health component with regeneration
      health_component = %{current: 80, max: 100, regen_rate: 15}
      Entity.add_component(entity_pid, :health, health_component)

      # Process tick - should regenerate to 95 (80 + 15)
      tick_data = %{tick_number: 1, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      updated_health = Entity.get_component(entity_pid, :health)
      assert updated_health.current == 95

      # Process another tick - should regenerate to 100 (capped at max)
      tick_data = %{tick_number: 2, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      final_health = Entity.get_component(entity_pid, :health)
      assert final_health.current == 100
    end

    test "mana regeneration works correctly", %{entity_pid: entity_pid} do
      # Add mana component
      mana_component = %{current: 30, max: 50, regen_rate: 8}
      Entity.add_component(entity_pid, :mana, mana_component)

      # Process tick
      tick_data = %{tick_number: 1, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      updated_mana = Entity.get_component(entity_pid, :mana)
      # 30 + 8
      assert updated_mana.current == 38
    end

    test "stamina regeneration works correctly", %{entity_pid: entity_pid} do
      # Add stamina component
      stamina_component = %{current: 60, max: 75, regen_rate: 12}
      Entity.add_component(entity_pid, :stamina, stamina_component)

      # Process tick
      tick_data = %{tick_number: 1, timestamp: DateTime.utc_now()}
      Entity.process_world_tick(entity_pid, tick_data)

      updated_stamina = Entity.get_component(entity_pid, :stamina)
      # 60 + 12
      assert updated_stamina.current == 72
    end
  end
end
