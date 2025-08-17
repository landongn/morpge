defmodule More.Mud.Registry.EntityRegistryTest do
  use ExUnit.Case, async: false
  alias More.Mud.Registry.EntityRegistry

  setup do
    # Start the Entity Registry for testing
    start_supervised!(EntityRegistry)
    :ok
  end

  describe "entity registration" do
    test "can register a new entity" do
      entity_id = "test_entity_001"
      entity_pid = self()
      metadata = %{type: :player, zone: "starting_zone", room: "room_001"}

      assert :ok = EntityRegistry.register(entity_id, entity_pid, metadata)

      # Verify entity is registered
      registered_metadata = EntityRegistry.get_metadata(entity_id)
      assert registered_metadata != nil
      assert registered_metadata.type == :player
      assert registered_metadata.zone == "starting_zone"
      assert registered_metadata.room == "room_001"
      assert registered_metadata.pid == entity_pid
    end

    test "returns error when registering duplicate entity" do
      entity_id = "test_entity_002"
      entity_pid = self()
      metadata = %{type: :npc, zone: "zone_1", room: "room_1"}

      # First registration should succeed
      assert :ok = EntityRegistry.register(entity_id, entity_pid, metadata)

      # Second registration should fail
      assert {:error, :entity_already_exists} =
               EntityRegistry.register(entity_id, entity_pid, metadata)
    end

    test "registers entity with default status when not specified" do
      entity_id = "test_entity_003"
      entity_pid = self()
      metadata = %{type: :mob, zone: "dungeon_zone"}

      assert :ok = EntityRegistry.register(entity_id, entity_pid, metadata)

      registered_metadata = EntityRegistry.get_metadata(entity_id)
      assert registered_metadata.status == :active
    end
  end

  describe "entity unregistration" do
    test "can unregister an entity" do
      entity_id = "test_entity_004"
      entity_pid = self()
      metadata = %{type: :item, zone: "inventory"}

      # Register first
      assert :ok = EntityRegistry.register(entity_id, entity_pid, metadata)
      assert EntityRegistry.get_metadata(entity_id) != nil

      # Unregister
      assert :ok = EntityRegistry.unregister(entity_id)
      assert EntityRegistry.get_metadata(entity_id) == nil
    end

    test "returns error when unregistering non-existent entity" do
      assert {:error, :entity_not_found} = EntityRegistry.unregister("nonexistent_entity")
    end
  end

  describe "entity lookup" do
    test "can get entity PID by ID" do
      entity_id = "test_entity_005"
      entity_pid = self()
      metadata = %{type: :player}

      EntityRegistry.register(entity_id, entity_pid, metadata)

      found_pid = EntityRegistry.get_pid(entity_id)
      assert found_pid == entity_pid
    end

    test "returns nil for non-existent entity" do
      found_pid = EntityRegistry.get_pid("nonexistent_entity")
      assert found_pid == nil
    end
  end

  describe "entity queries" do
    setup do
      # Register several test entities
      EntityRegistry.register("player_001", self(), %{
        type: :player,
        zone: "starting_zone",
        room: "room_001",
        components: [:health, :inventory]
      })

      EntityRegistry.register("player_002", self(), %{
        type: :player,
        zone: "starting_zone",
        room: "room_002",
        components: [:health, :mana]
      })

      EntityRegistry.register("npc_001", self(), %{
        type: :npc,
        zone: "starting_zone",
        room: "room_001",
        components: [:health]
      })

      EntityRegistry.register("mob_001", self(), %{
        type: :mob,
        zone: "dungeon_zone",
        room: "room_005",
        components: [:health, :combat]
      })

      EntityRegistry.register("item_001", self(), %{
        type: :item,
        zone: "inventory",
        room: nil,
        components: [:durability]
      })

      :ok
    end

    test "can get entities by type" do
      players = EntityRegistry.get_entities_by_type(:player)
      npcs = EntityRegistry.get_entities_by_type(:npc)
      mobs = EntityRegistry.get_entities_by_type(:mob)
      items = EntityRegistry.get_entities_by_type(:item)

      assert length(players) == 2
      assert length(npcs) == 1
      assert length(mobs) == 1
      assert length(items) == 1

      # Verify player details
      player_ids = Enum.map(players, fn {id, _metadata} -> id end)
      assert "player_001" in player_ids
      assert "player_002" in player_ids
    end

    test "can get entities in zone" do
      starting_zone_entities = EntityRegistry.get_entities_in_zone("starting_zone")
      dungeon_zone_entities = EntityRegistry.get_entities_in_zone("dungeon_zone")

      # 2 players + 1 npc
      assert length(starting_zone_entities) == 3
      # 1 mob
      assert length(dungeon_zone_entities) == 1

      # Verify starting zone entities
      starting_ids = Enum.map(starting_zone_entities, fn {id, _metadata} -> id end)
      assert "player_001" in starting_ids
      assert "player_002" in starting_ids
      assert "npc_001" in starting_ids
    end

    test "can get entities in room" do
      room_001_entities = EntityRegistry.get_entities_in_room("room_001")
      room_002_entities = EntityRegistry.get_entities_in_room("room_002")
      room_005_entities = EntityRegistry.get_entities_in_room("room_005")

      # player_001 + npc_001
      assert length(room_001_entities) == 2
      # player_002
      assert length(room_002_entities) == 1
      # mob_001
      assert length(room_005_entities) == 1
    end

    test "can get entities with component" do
      health_entities = EntityRegistry.get_entities_with_component(:health)
      inventory_entities = EntityRegistry.get_entities_with_component(:inventory)
      mana_entities = EntityRegistry.get_entities_with_component(:mana)
      combat_entities = EntityRegistry.get_entities_with_component(:combat)

      # 2 players + 1 npc + 1 mob
      assert length(health_entities) == 4
      # 1 player
      assert length(inventory_entities) == 1
      # 1 player
      assert length(mana_entities) == 1
      # 1 mob
      assert length(combat_entities) == 1
    end

    test "returns empty list for non-existent queries" do
      assert EntityRegistry.get_entities_by_type(:nonexistent) == []
      assert EntityRegistry.get_entities_in_zone("nonexistent_zone") == []
      assert EntityRegistry.get_entities_in_room("nonexistent_room") == []
      assert EntityRegistry.get_entities_with_component(:nonexistent_component) == []
    end
  end

  describe "metadata updates" do
    test "can update entity metadata" do
      entity_id = "test_entity_006"
      entity_pid = self()
      metadata = %{type: :player, zone: "old_zone", room: "old_room"}

      EntityRegistry.register(entity_id, entity_pid, metadata)

      # Update zone
      assert :ok = EntityRegistry.update_metadata(entity_id, :zone, "new_zone")
      updated_metadata = EntityRegistry.get_metadata(entity_id)
      assert updated_metadata.zone == "new_zone"

      # Update room
      assert :ok = EntityRegistry.update_metadata(entity_id, :room, "new_room")
      updated_metadata = EntityRegistry.get_metadata(entity_id)
      assert updated_metadata.room == "new_room"

      # Update status
      assert :ok = EntityRegistry.update_metadata(entity_id, :status, :inactive)
      updated_metadata = EntityRegistry.get_metadata(entity_id)
      assert updated_metadata.status == :inactive
    end

    test "returns error when updating non-existent entity" do
      assert {:error, :entity_not_found} =
               EntityRegistry.update_metadata("nonexistent", :zone, "new_zone")
    end

    test "updates indexes when metadata changes" do
      entity_id = "test_entity_007"
      entity_pid = self()
      metadata = %{type: :player, zone: "zone_1", room: "room_1"}

      EntityRegistry.register(entity_id, entity_pid, metadata)

      # Verify entity appears in both zone and room indexes
      zone_entities = EntityRegistry.get_entities_in_zone("zone_1")
      room_entities = EntityRegistry.get_entities_in_room("room_1")
      assert length(zone_entities) == 1
      assert length(room_entities) == 1

      # Move entity to new zone and room
      EntityRegistry.update_metadata(entity_id, :zone, "zone_2")
      EntityRegistry.update_metadata(entity_id, :room, "room_2")

      # Verify entity moved in indexes
      old_zone_entities = EntityRegistry.get_entities_in_zone("zone_1")
      new_zone_entities = EntityRegistry.get_entities_in_zone("zone_2")
      old_room_entities = EntityRegistry.get_entities_in_room("room_1")
      new_room_entities = EntityRegistry.get_entities_in_room("room_2")

      assert length(old_zone_entities) == 0
      assert length(new_zone_entities) == 1
      assert length(old_room_entities) == 0
      assert length(new_room_entities) == 1
    end

    test "updates component indexes when components change" do
      entity_id = "test_entity_008"
      entity_pid = self()
      metadata = %{type: :player, components: [:health, :inventory]}

      EntityRegistry.register(entity_id, entity_pid, metadata)

      # Verify entity appears in component indexes
      health_entities = EntityRegistry.get_entities_with_component(:health)
      inventory_entities = EntityRegistry.get_entities_with_component(:inventory)
      assert length(health_entities) == 1
      assert length(inventory_entities) == 1

      # Update components
      EntityRegistry.update_metadata(entity_id, :components, [:health, :mana])

      # Verify component indexes updated
      health_entities = EntityRegistry.get_entities_with_component(:health)
      inventory_entities = EntityRegistry.get_entities_with_component(:inventory)
      mana_entities = EntityRegistry.get_entities_with_component(:mana)

      assert length(health_entities) == 1
      assert length(inventory_entities) == 0
      assert length(mana_entities) == 1
    end
  end

  describe "statistics" do
    test "can get entity count" do
      # Start with 0 entities
      assert EntityRegistry.get_entity_count() == 0

      # Register some entities
      EntityRegistry.register("entity_1", self(), %{type: :player})
      EntityRegistry.register("entity_2", self(), %{type: :npc})
      EntityRegistry.register("entity_3", self(), %{type: :mob})

      # Should have 3 entities
      assert EntityRegistry.get_entity_count() == 3

      # Unregister one
      EntityRegistry.unregister("entity_2")
      assert EntityRegistry.get_entity_count() == 2
    end

    test "can get detailed statistics" do
      # Register entities of different types
      EntityRegistry.register("player_1", self(), %{type: :player, zone: "zone_1"})
      EntityRegistry.register("player_2", self(), %{type: :player, zone: "zone_1"})
      EntityRegistry.register("npc_1", self(), %{type: :npc, zone: "zone_2"})
      EntityRegistry.register("mob_1", self(), %{type: :mob, zone: "zone_1"})

      stats = EntityRegistry.get_stats()

      assert stats.total_entities == 4
      assert stats.by_type.player == 2
      assert stats.by_type.npc == 1
      assert stats.by_type.mob == 1
      assert stats.by_zone["zone_1"] == 3
      assert stats.by_zone["zone_2"] == 1
    end
  end
end
