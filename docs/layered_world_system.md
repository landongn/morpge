# Layered World System

## Overview

The Layered World System is a core component of the More MUD engine that provides a flexible, tile-based world representation with multiple layers. Each layer represents different aspects of the world, allowing for complex interactions and dynamic content.

## Architecture

### Core Components

1. **WorldLayer** - Database schema representing a world layer
2. **LayerMap** - ASCII-based map data for each layer
3. **LayerEntity** - Dynamic entities within layers
4. **LayerConnection** - Inter-layer relationships and transitions
5. **WorldLayerServer** - GenServer managing individual layers
6. **WorldLayerSupervisor** - Supervisor for all layer servers
7. **WorldLayerRegistry** - Registry for tracking active layers
8. **WorldManager** - Central coordinator for the world system

### Layer Types

The system includes six core layers:

1. **Ground** (Layer 1) - Foundation terrain and base geography
   - Characters: `.` (grass), `~` (water), `^` (mountain), `#` (impassable)
   - Properties: movement cost, visibility

2. **Atmosphere** (Layer 2) - Environmental effects and visibility
   - Characters: ` ` (clear), `f` (fog), `r` (rain), `s` (storm)
   - Properties: weather effects, visibility modifiers

3. **Plants** (Layer 3) - Vegetation and natural resources
   - Characters: ` ` (empty), `t` (tree), `b` (bush), `f` (flowers), `g` (grass)
   - Properties: growth rates, harvestable resources

4. **Structures** (Layer 4) - Buildings and architectural elements
   - Characters: ` ` (empty), `H` (house), `S` (shop), `T` (tower), `W` (wall), `C` (castle)
   - Properties: building types, durability

5. **Floor Plans** (Layer 5) - Interior layouts and room connections
   - Characters: ` ` (empty), `r` (room), `h` (hallway), `s` (stairs), `c` (corridor)
   - Properties: room types, lighting

6. **Doors** (Layer 6) - Passageways and zone transitions
   - Characters: ` ` (empty), `D` (door), `G` (gate), `P` (portal), `T` (tunnel)
   - Properties: door types, lock mechanisms

## Database Schema

### Tables

- `world_layers` - Core layer definitions
- `layer_maps` - ASCII map data for each layer/zone combination
- `layer_entities` - Dynamic entities within layers
- `layer_connections` - Inter-layer connections and transitions

### Key Fields

- `layer_order` - Determines rendering order (lower numbers render first)
- `tick_interval` - How often the layer processes world ticks (in milliseconds)
- `metadata` - JSON field for layer-specific configuration
- `map_data` - ASCII text representing the visual layout

## Usage

### Starting the System

```elixir
# The system starts automatically with the application
# You can also start it manually:

{:ok, _pid} = More.Mud.World.WorldManager.start_link([])
```

### Creating a Zone

```elixir
# Create a new zone with all required layers
{:ok, layers} = More.Mud.World.WorldManager.create_zone("forest_zone", %{
  "description" => "A dense forest area",
  "difficulty" => "medium"
})
```

### Working with Layers

```elixir
# Get all layers for a zone
layers = More.Mud.World.WorldManager.get_zone_layers("forest_zone")

# Get a specific layer's map
map = More.Mud.World.WorldLayerServer.get_map("ground", "forest_zone")

# Get a character at specific coordinates
char = More.Mud.World.WorldLayerServer.get_at("ground", "forest_zone", 5, 5)

# Set a character at specific coordinates
:ok = More.Mud.World.WorldLayerServer.set_at("ground", "forest_zone", 5, 5, "t")
```

### Adding Entities

```elixir
# Add an entity to a layer
entity_data = %{
  entity_type: "tree",
  entity_id: "tree_001",
  x: 5,
  y: 5,
  properties: %{
    "species" => "oak",
    "age" => 25,
    "health" => 100
  }
}

:ok = More.Mud.World.WorldManager.add_entity_to_layer("plants", "forest_zone", entity_data)
```

### World Ticks

The system automatically processes world ticks every 3 seconds. Each layer can implement custom tick processing:

```elixir
# Custom tick processing in WorldLayerServer
defp process_plants_tick(state, _tick_data) do
  # Implement plant growth, seasonal changes, etc.
  updated_entities = Enum.map(state.entities, fn {id, entity} ->
    if entity.entity_type == "tree" do
      # Simulate tree growth
      updated_props = Map.update(entity.properties, "age", 1, &(&1 + 1))
      %{entity | properties: updated_props}
    else
      entity
    end
  end)
  
  %{state | entities: updated_entities}
end
```

## World Viewer Interface

The system includes a LiveView-based world viewer that provides:

- **Top-down 2D tile view** of the world
- **Layer visibility toggles** for showing/hiding specific layers
- **Player movement controls** with 8-directional movement
- **Interactive editing mode** for modifying the world
- **Real-time updates** from the world system
- **Zoom controls** for adjusting view size

### Using the World Viewer

1. Navigate to the game interface
2. Select the World Viewer component
3. Use the layer controls to show/hide specific layers
4. Use movement controls to navigate the world
5. Enable editing mode to modify the world
6. Select tiles from the palette and click to place them

## Customization

### Adding New Layers

1. Create a new layer record in the database
2. Implement custom tick processing in `WorldLayerServer`
3. Add layer-specific styling in the CSS
4. Update the world viewer template

### Custom Tile Types

1. Define new characters in the layer metadata
2. Add styling rules in the CSS
3. Implement any special behavior in the tick processing

### Layer Interactions

Layers can interact through the connection system:

```elixir
# Get connections between layers
connections = More.Mud.World.WorldLayerServer.get_connections("ground", "forest_zone")

# Check if a position has a connection
case More.Mud.World.LayerConnection.at_position(layer_id, zone_name, x, y) do
  [connection | _] -> 
    # Handle the connection
    {target_x, target_y, target_layer} = LayerConnection.get_target_position(connection, layer_id, x, y)
    # Move entity to new position/layer
  
  [] -> 
    # No connection at this position
end
```

## Performance Considerations

- **Map Size**: Large maps (>100x100) may impact performance
- **Entity Count**: Each entity adds overhead to tick processing
- **Update Frequency**: Consider adjusting tick intervals for complex layers
- **Memory Usage**: Monitor memory usage with many active layers

## Troubleshooting

### Common Issues

1. **Layers not updating**: Check if the layer server is running
2. **Entities not appearing**: Verify entity coordinates are within map bounds
3. **Performance issues**: Reduce tick frequency or map size
4. **Database errors**: Ensure migrations have been run

### Debugging

```elixir
# Check layer status
statuses = More.Mud.World.WorldManager.get_layer_statuses()

# Check registry
layers = More.Mud.Registry.WorldLayerRegistry.all_layers()

# Check specific layer
info = More.Mud.Supervision.WorldLayerSupervisor.get_layer_info("ground", "forest_zone")
```

## Future Enhancements

- **Procedural generation** for automatic world creation
- **Layer blending** for smooth transitions
- **Advanced pathfinding** across multiple layers
- **Weather systems** affecting multiple layers
- **Seasonal changes** with layer-specific effects
- **Multi-zone support** with seamless transitions
