# Entity System Design

## Overview

The entity system is the heart of our MUD engine, managing all game objects (players, NPCs, mobs, items) through a robust, supervised, fault-tolerant architecture. Each entity is a GenServer with components, managed through a sophisticated supervision tree.

## Core Principles

### 1. **Every Entity is a GenServer**
- **Benefits**: Natural fault isolation, independent state management, easy supervision
- **Implementation**: Each entity runs in its own process with OTP supervision

### 2. **Component-Based Behavior**
- **Benefits**: Flexible composition, easy to extend, clear separation of concerns
- **Implementation**: Components stored as maps in GenServer state

### 3. **Supervised Lifecycle**
- **Benefits**: Automatic recovery, fault tolerance, controlled spawning
- **Implementation**: Multi-level supervision tree with restart strategies

### 4. **Rule-Based Spawning**
- **Benefits**: Configurable, data-driven, easy to modify
- **Implementation**: Spawn rules defined in configuration, processed by spawn managers

## Entity Types and Hierarchy

### Entity Classification
```
Entity (Base GenServer)
├── Living Entity
│   ├── Player
│   ├── NPC
│   └── Mob
├── Item Entity
│   ├── Weapon
│   ├── Armor
│   └── Consumable
└── World Entity
    ├── Room
    ├── Exit
    └── Trigger
```

### Entity States
- **Spawning**: Entity is being created
- **Active**: Entity is fully functional
- **Inactive**: Entity is temporarily disabled
- **Despawning**: Entity is being removed
- **Dead**: Entity has been destroyed

## Supervision Architecture

### Entity Supervision Tree
```
EntitySupervisor
├── PlayerSupervisor
│   ├── Player1 (GenServer)
│   ├── Player2 (GenServer)
│   └── ...
├── NpcSupervisor
│   ├── Npc1 (GenServer)
│   ├── Npc2 (GenServer)
│   └── ...
├── MobSupervisor
│   ├── Mob1 (GenServer)
│   ├── Mob2 (GenServer)
│   └── ...
└── ItemSupervisor
    ├── Item1 (GenServer)
    ├── Item2 (GenServer)
    └── ...
```

### Supervision Strategies
- **PlayerSupervisor**: `:one_for_one` - Player failures don't affect others
- **NpcSupervisor**: `:one_for_one` - NPC failures don't affect others
- **MobSupervisor**: `:one_for_one` - Mob failures don't affect others
- **ItemSupervisor**: `:one_for_one` - Item failures don't affect others

### Restart Strategies
- **Players**: `:permanent` - Always restart (important for game state)
- **NPCs**: `:temporary` - Restart only if explicitly requested
- **Mobs**: `:temporary` - Restart based on spawn rules
- **Items**: `:temporary` - Restart only if in use

## Entity Registry and Management

### Entity Registry (GenServer)
**Purpose**: Central registry for all entities in the game world
**Responsibilities**:
- Track all entity PIDs and metadata
- Provide fast entity lookup
- Manage entity lifecycles
- Handle entity queries and filtering

**State Structure**:
```elixir
%{
  entities: %{
    "player_001" => %{
      pid: #PID<0.123.0>,
      type: :player,
      zone: "starting_zone",
      room: "room_001",
      components: [:health, :inventory, :position],
      last_seen: ~U[2025-08-16 23:00:00Z]
    }
  },
  indexes: %{
    by_type: %{
      player: ["player_001", "player_002"],
      npc: ["npc_001", "npc_002"],
      mob: ["mob_001", "mob_002"]
    },
    by_zone: %{
      "starting_zone" => ["player_001", "npc_001"],
      "dungeon_zone" => ["mob_001", "mob_002"]
    },
    by_room: %{
      "room_001" => ["player_001", "npc_001"],
      "room_002" => ["mob_001"]
    },
    by_component: %{
      health: ["player_001", "npc_001", "mob_001"],
      inventory: ["player_001", "npc_001"]
    }
  }
}
```

### Registry Operations
```elixir
# Register entity
EntityRegistry.register(entity_id, entity_pid, metadata)

# Lookup entity
entity_pid = EntityRegistry.get_pid("player_001")

# Find entities by criteria
players = EntityRegistry.get_entities_by_type(:player)
room_entities = EntityRegistry.get_entities_in_room("room_001")
health_entities = EntityRegistry.get_entities_with_component(:health)

# Update entity metadata
EntityRegistry.update_metadata("player_001", :room, "room_002")

# Unregister entity
EntityRegistry.unregister("player_001")
```

## Entity Spawning System

### Spawn Rule Engine
**Purpose**: Configurable, data-driven entity spawning
**Components**:
- Spawn Rule Parser
- Spawn Rule Evaluator
- Spawn Manager
- Spawn Scheduler

### Spawn Rule Structure
```elixir
%{
  rule_id: "goblin_spawn_001",
  entity_type: :mob,
  template: "goblin_warrior",
  spawn_points: [
    %{
      zone: "dungeon_zone",
      room: "room_005",
      probability: 0.8,
      max_count: 3,
      respawn_time: 300  # 5 minutes
    }
  ],
  conditions: [
    %{
      type: :player_presence,
      room: "room_005",
      min_players: 1,
      max_players: 5
    },
    %{
      type: :time_of_day,
      start_hour: 20,  # 8 PM
      end_hour: 6      # 6 AM
    }
  ],
  behavior: %{
    ai_type: :aggressive,
    patrol_route: ["room_005", "room_006", "room_007"],
    combat_style: :melee
  }
}
```

### Spawn Rule Processing
1. **Rule Loading**: Rules loaded from configuration files
2. **Rule Evaluation**: Conditions checked against current world state
3. **Spawn Decision**: Spawn if all conditions are met
4. **Entity Creation**: Entity spawned using template
5. **State Management**: Entity added to registry and supervision

### Spawn Manager (GenServer)
**Purpose**: Manages entity spawning based on rules
**Responsibilities**:
- Load and parse spawn rules
- Evaluate spawn conditions
- Create and spawn entities
- Manage spawn schedules
- Handle respawning

**State**:
```elixir
%{
  spawn_rules: %{},
  active_spawns: %{},
  spawn_schedules: %{},
  templates: %{}
}
```

## Entity Templates and Components

### Entity Templates
**Purpose**: Predefined entity configurations for consistent spawning
**Structure**:
```elixir
%{
  template_id: "goblin_warrior",
  entity_type: :mob,
  base_components: %{
    health: %{current: 50, max: 50, regen_rate: 2},
    mana: %{current: 20, max: 20, regen_rate: 1},
    stamina: %{current: 75, max: 75, regen_rate: 3},
    combat: %{attack: 15, defense: 8, damage: "1d6+2"},
    ai: %{type: :aggressive, behavior: :patrol}
  },
  spawn_components: %{
    position: %{zone: "dungeon_zone", room: "room_005"},
    inventory: %{items: ["rusty_sword", "leather_armor"]},
    experience: %{level: 3, exp: 150, next_level: 300}
  }
}
```

### Component System
**Purpose**: Flexible entity behavior composition
**Core Components**:
- **Health**: Current/max health, regeneration
- **Mana**: Current/max mana, regeneration
- **Stamina**: Current/max stamina, regeneration
- **Position**: Zone, room, coordinates
- **Inventory**: Items, weight, capacity
- **Combat**: Attack, defense, damage
- **AI**: Behavior type, decision making
- **Experience**: Level, experience points
- **Status**: Buffs, debuffs, effects

**Component Operations**:
```elixir
# Add component
Entity.add_component(entity_pid, :health, %{current: 100, max: 100})

# Update component
Entity.update_component(entity_pid, :health, :current, 75)

# Remove component
Entity.remove_component(entity_pid, :health)

# Query component
health = Entity.get_component(entity_pid, :health)
```

## Fault Tolerance and Recovery

### Entity Failure Handling
1. **Process Crash**: Entity automatically restarts via supervision
2. **State Corruption**: Entity restarts with clean state
3. **Component Errors**: Failed components are reset to defaults
4. **Communication Failures**: Messages are queued and retried

### Recovery Strategies
- **Immediate Restart**: For critical entities (players)
- **Delayed Restart**: For non-critical entities (mobs, items)
- **State Restoration**: Restore from last known good state
- **Template Reapplication**: Reapply entity template on restart

### Health Monitoring
- **Heartbeat System**: Entities report health status
- **Watchdog Timers**: Detect stuck or unresponsive entities
- **Performance Metrics**: Track entity processing times
- **Memory Monitoring**: Monitor entity memory usage

## Performance Considerations

### Entity Processing
- **Batch Operations**: Process entities in batches for efficiency
- **Lazy Loading**: Load entity data on demand
- **Caching**: Cache frequently accessed entity data
- **Indexing**: Maintain indexes for fast entity queries

### Memory Management
- **Component Pooling**: Reuse component structures
- **State Compression**: Compress entity state when possible
- **Garbage Collection**: Monitor and optimize GC behavior
- **Memory Limits**: Set limits on entity counts and state size

### Scalability Features
- **Entity Distribution**: Distribute entities across nodes
- **Load Balancing**: Balance entity processing across supervisors
- **Horizontal Scaling**: Add more supervisors as needed
- **State Partitioning**: Partition entity state across nodes

## Implementation Phases

### Phase 1: Core Entity System
- Basic Entity GenServer
- Entity Registry
- Simple component system
- Basic supervision tree

### Phase 2: Spawning System
- Spawn rule engine
- Entity templates
- Spawn managers
- Respawn logic

### Phase 3: Advanced Features
- Component inheritance
- Dynamic component loading
- Advanced AI behaviors
- Performance optimization

### Phase 4: Distribution
- Multi-node support
- Entity migration
- Load balancing
- Fault tolerance

---

*This document will be updated as we implement and refine the entity system.*
