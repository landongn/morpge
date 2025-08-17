# Technical Architecture

## System Overview

The MUD engine is built around several key architectural patterns that leverage Elixir's strengths:

1. **Actor-Based Entities**: Each game object is a GenServer
2. **Event-Driven Processing**: GenStage handles world ticks and events
3. **Supervision Trees**: OTP supervision for fault tolerance
4. **Component Composition**: ECS pattern for flexible entity behavior

## Core Components

### 1. World Manager (GenServer)
**Purpose**: Orchestrates the entire game world
**Responsibilities**:
- Manages world tick timing
- Coordinates zone loading/unloading
- Handles global game state
- Manages entity registry

**State**:
```elixir
%{
  world_tick: 0,
  zones: %{},
  entity_registry: %{},
  global_settings: %{}
}
```

### 2. Zone Manager (GenServer)
**Purpose**: Manages a logical group of connected areas
**Responsibilities**:
- Loads zone data from configuration
- Manages room instances
- Handles zone-specific events
- Coordinates entity spawning

**State**:
```elixir
%{
  zone_id: "starting_zone",
  rooms: %{},
  npcs: %{},
  spawn_points: %{},
  zone_settings: %{}
}
```

### 3. Room (GenServer)
**Purpose**: Represents a location in the game world
**Responsibilities**:
- Manages room contents (players, NPCs, items)
- Handles exits and movement
- Processes room-specific events
- Manages room state

**State**:
```elixir
%{
  room_id: "room_001",
  position: {x: 0, y: 0, z: 0},
  description: "A cozy tavern...",
  exits: %{},
  contents: %{},
  room_flags: %{}
}
```

### 4. Entity (GenServer)
**Purpose**: Base for all game objects (players, NPCs, items)
**Responsibilities**:
- Manages entity state
- Processes world ticks
- Handles entity-specific logic
- Manages component data

**State**:
```elixir
%{
  entity_id: "player_001",
  entity_type: :player,
  components: %{},
  position: nil,
  state: :active
}
```

## World Tick System

### GenStage Pipeline
```
WorldTickProducer → [TickConsumer1, TickConsumer2, ...] → StateUpdate
```

**WorldTickProducer**:
- Generates tick events every 3 seconds
- Broadcasts to all consumers
- Handles backpressure

**TickConsumers**:
- Process different entity types
- Update entity state
- Generate game events

**StateUpdate**:
- Synchronizes world state
- Triggers client updates
- Handles persistence

### Tick Processing Flow
1. **Tick Generation**: WorldTickProducer creates tick event
2. **Consumer Processing**: Each consumer processes relevant entities
3. **State Updates**: Entities update their state based on tick
4. **Event Generation**: New events created from state changes
5. **Client Updates**: Clients receive updated game state

## Entity-Component-System Implementation

### Component Storage
**Approach**: Map-based storage in GenServer state
**Benefits**:
- Fast access and modification
- Easy to serialize/deserialize
- Natural fit with GenServer state
- Simple to debug

**Structure**:
```elixir
%{
  health: %{current: 100, max: 100, regen_rate: 5},
  mana: %{current: 50, max: 50, regen_rate: 3},
  stamina: %{current: 75, max: 75, regen_rate: 2},
  inventory: %{items: [], weight: 0, max_weight: 100}
}
```

### System Processing
**Approach**: Systems query entities for specific components
**Implementation**:
- Entity registry maintains component indexes
- Systems query registry for relevant entities
- Batch processing for performance
- Event-driven updates

**Example**:
```elixir
# Health system processes all entities with health component
def process_health_tick do
  entities = EntityRegistry.get_entities_with_component(:health)
  
  Enum.each(entities, fn entity ->
    if has_regen_component?(entity) do
      regen_health(entity)
    end
  end)
end
```

## Entity Communication

### Message Passing Patterns
1. **Direct Calls**: For immediate, synchronous operations
2. **Message Passing**: For asynchronous, decoupled operations
3. **Event Broadcasting**: For system-wide notifications
4. **Registry Queries**: For finding and querying entities

### Communication Examples
```elixir
# Direct call for immediate action
GenServer.call(player_pid, {:take_damage, 10})

# Message for asynchronous action
send(player_pid, {:experience_gain, 100})

# Event broadcast for system-wide notification
GameEvents.broadcast(:player_level_up, %{player_id: "player_001"})

# Registry query for finding entities
nearby_entities = EntityRegistry.get_entities_in_room("room_001")
```

## Supervision Strategy

### Supervision Tree
```
MudSupervisor
├── WorldManager
├── ZoneSupervisor
│   ├── ZoneManager1
│   ├── ZoneManager2
│   └── ...
├── EntitySupervisor
│   ├── PlayerSupervisor
│   ├── NpcSupervisor
│   └── ItemSupervisor
└── SystemSupervisor
    ├── HealthSystem
    ├── CombatSystem
    └── MovementSystem
```

### Fault Tolerance
- **Entity Isolation**: Entity failures don't affect others
- **Zone Isolation**: Zone failures don't affect other zones
- **System Isolation**: System failures don't crash the world
- **Automatic Recovery**: Failed entities automatically restart

## Performance Considerations

### Entity Processing
- **Batch Processing**: Process entities in batches for efficiency
- **Lazy Loading**: Load zones and entities on demand
- **Caching**: Cache frequently accessed data
- **Indexing**: Maintain indexes for fast entity queries

### Memory Management
- **Component Pooling**: Reuse component structures
- **State Compression**: Compress entity state when possible
- **Garbage Collection**: Monitor and optimize GC behavior
- **Memory Limits**: Set limits on entity counts and state size

## Scalability Features

### Multi-Node Support
- **Distributed Entities**: Entities can run on different nodes
- **Load Balancing**: Distribute processing across nodes
- **Node Failover**: Automatic failover for failed nodes
- **State Synchronization**: Keep state consistent across nodes

### Horizontal Scaling
- **Zone Distribution**: Distribute zones across nodes
- **Entity Migration**: Move entities between nodes for load balancing
- **Event Distribution**: Distribute event processing across nodes
- **State Partitioning**: Partition world state across nodes

---

*This document will be updated as we implement and refine the architecture.*
