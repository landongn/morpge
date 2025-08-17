# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     More.Repo.insert!(%More.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Create the core world layers
alias More.Repo
alias More.Mud.World.{WorldLayer, LayerMap, LayerEntity, LayerConnection}

# Clear existing data
Repo.delete_all(LayerConnection)
Repo.delete_all(LayerEntity)
Repo.delete_all(LayerMap)
Repo.delete_all(WorldLayer)

# Create the core world layers
layers = [
  %{
    name: "ground",
    display_name: "Ground",
    description: "Foundation terrain and base geography",
    layer_order: 1,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "movement_cost" => %{
        # Grass
        "." => 1,
        # Water
        "~" => 2,
        # Mountain
        "^" => 3,
        # Impassable
        "#" => 0
      },
      "visibility" => %{
        # Full visibility
        "." => 100,
        # Reduced visibility
        "~" => 80,
        # Limited visibility
        "^" => 60,
        # No visibility
        "#" => 0
      }
    }
  },
  %{
    name: "atmosphere",
    display_name: "Atmosphere",
    description: "Environmental effects, weather, and visibility",
    layer_order: 2,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "weather_effects" => %{
        "clear" => %{"visibility_modifier" => 0, "movement_modifier" => 0},
        "fog" => %{"visibility_modifier" => -20, "movement_modifier" => 0},
        "rain" => %{"visibility_modifier" => -10, "movement_modifier" => 1},
        "storm" => %{"visibility_modifier" => -30, "movement_modifier" => 2}
      }
    }
  },
  %{
    name: "plants",
    display_name: "Plants",
    description: "Vegetation, trees, and natural resources",
    layer_order: 3,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "growth_rates" => %{
        # Tree
        "t" => 1,
        # Bush
        "b" => 2,
        # Flowers
        "f" => 3,
        # Grass
        "g" => 4
      },
      "harvestable" => ["t", "b", "f", "g"]
    }
  },
  %{
    name: "structures",
    display_name: "Structures",
    description: "Buildings, walls, and architectural elements",
    layer_order: 4,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "building_types" => %{
        "H" => "house",
        "S" => "shop",
        "T" => "tower",
        "W" => "wall",
        "C" => "castle"
      },
      "durability" => %{
        "H" => 100,
        "S" => 80,
        "T" => 120,
        "W" => 150,
        "C" => 200
      }
    }
  },
  %{
    name: "floor_plans",
    display_name: "Floor Plans",
    description: "Interior layouts and room connections",
    layer_order: 5,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "room_types" => %{
        "r" => "room",
        "h" => "hallway",
        "s" => "stairs",
        "c" => "corridor"
      },
      "lighting" => %{
        "r" => "lit",
        "h" => "dim",
        "s" => "dark",
        "c" => "dim"
      }
    }
  },
  %{
    name: "doors",
    display_name: "Doors",
    description: "Passageways, portals, and zone transitions",
    layer_order: 6,
    is_active: true,
    tick_interval: 3000,
    metadata: %{
      "door_types" => %{
        "D" => "door",
        "G" => "gate",
        "P" => "portal",
        "T" => "tunnel"
      },
      "lock_mechanisms" => %{
        "D" => "simple",
        "G" => "complex",
        "P" => "magical",
        "T" => "none"
      }
    }
  }
]

# Insert the layers
inserted_layers =
  Enum.map(layers, fn layer_data ->
    %WorldLayer{}
    |> WorldLayer.changeset(layer_data)
    |> Repo.insert!()
  end)

IO.puts("Created #{length(inserted_layers)} world layers")

# Create a sample zone with maps for each layer
zone_name = "starting_village"

# Sample map data for each layer
sample_maps = [
  %{
    layer_name: "ground",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  },
  %{
    layer_name: "atmosphere",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  },
  %{
    layer_name: "plants",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  },
  %{
    layer_name: "structures",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  },
  %{
    layer_name: "floor_plans",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  },
  %{
    layer_name: "doors",
    map_data: """
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    ....................
    """,
    width: 20,
    height: 20
  }
]

# Insert the maps
Enum.each(sample_maps, fn map_data ->
  layer = Enum.find(inserted_layers, fn l -> l.name == map_data.layer_name end)

  %LayerMap{}
  |> LayerMap.changeset(%{
    layer_id: layer.id,
    zone_name: zone_name,
    map_data: map_data.map_data,
    width: map_data.width,
    height: map_data.height,
    origin_x: 0,
    origin_y: 0,
    metadata: %{}
  })
  |> Repo.insert!()
end)

IO.puts("Created sample maps for zone: #{zone_name}")

# Create some sample entities
sample_entities = [
  %{
    layer_name: "plants",
    entity_type: "tree",
    entity_id: "tree_001",
    x: 5,
    y: 5,
    properties: %{
      "species" => "oak",
      "age" => 25,
      "health" => 100,
      "fruit" => "acorns"
    }
  },
  %{
    layer_name: "structures",
    entity_type: "house",
    entity_id: "house_001",
    x: 10,
    y: 10,
    properties: %{
      "owner" => "villager_001",
      "condition" => "good",
      "size" => "medium"
    }
  },
  %{
    layer_name: "doors",
    entity_type: "door",
    entity_id: "door_001",
    x: 10,
    y: 11,
    properties: %{
      "locked" => false,
      "key_required" => false,
      "durability" => 100
    }
  }
]

# Insert the entities
Enum.each(sample_entities, fn entity_data ->
  layer = Enum.find(inserted_layers, fn l -> l.name == entity_data.layer_name end)

  %LayerEntity{}
  |> LayerEntity.changeset(%{
    layer_id: layer.id,
    entity_type: entity_data.entity_type,
    entity_id: entity_data.entity_id,
    x: entity_data.x,
    y: entity_data.y,
    zone_name: zone_name,
    properties: entity_data.properties,
    is_active: true
  })
  |> Repo.insert!()
end)

IO.puts("Created #{length(sample_entities)} sample entities")

# Create some sample connections between layers
sample_connections = [
  %{
    source_layer_name: "ground",
    target_layer_name: "floor_plans",
    connection_type: "stairs",
    source_x: 15,
    source_y: 15,
    target_x: 15,
    target_y: 15,
    properties: %{
      "bidirectional" => true,
      "cost" => 1,
      "description" => "Stone stairs leading down"
    }
  },
  %{
    source_layer_name: "structures",
    target_layer_name: "floor_plans",
    connection_type: "door",
    source_x: 10,
    source_y: 11,
    target_x: 10,
    target_y: 11,
    properties: %{
      "bidirectional" => true,
      "cost" => 1,
      "description" => "Wooden door"
    }
  }
]

# Insert the connections
Enum.each(sample_connections, fn connection_data ->
  source_layer =
    Enum.find(inserted_layers, fn l -> l.name == connection_data.source_layer_name end)

  target_layer =
    Enum.find(inserted_layers, fn l -> l.name == connection_data.target_layer_name end)

  %LayerConnection{}
  |> LayerConnection.changeset(%{
    source_layer_id: source_layer.id,
    target_layer_id: target_layer.id,
    connection_type: connection_data.connection_type,
    source_x: connection_data.source_x,
    source_y: connection_data.source_y,
    target_x: connection_data.target_x,
    target_y: connection_data.target_y,
    zone_name: zone_name,
    properties: connection_data.properties
  })
  |> Repo.insert!()
end)

IO.puts("Created #{length(sample_connections)} sample connections")

IO.puts("Database seeding completed successfully!")
IO.puts("Created world with:")
IO.puts("  - #{length(inserted_layers)} layers")
IO.puts("  - 1 zone (#{zone_name})")
IO.puts("  - #{length(sample_entities)} entities")
IO.puts("  - #{length(sample_connections)} connections")
