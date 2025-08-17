# MUD Revival Design Document

## Project Overview

A revival of the classic MUD/DikuMUD style games built on Elixir's actor-based architecture. This project leverages Elixir's strengths in distributed systems, concurrency, and fault tolerance to create a modern, scalable MUD engine.

## Why Elixir?

- **Actor Model**: Natural fit for game entities (players, NPCs, mobs)
- **GenServer**: Perfect for stateful game objects
- **GenStage**: Excellent for handling game events and world ticks
- **OTP**: Built-in supervision and fault tolerance
- **Phoenix**: Real-time web interface for modern accessibility
- **Distributed**: Easy to scale across multiple nodes

## Core Architecture Principles

### 1. World Tick System
- **Frequency**: 3-second intervals
- **Purpose**: Synchronized game state updates
- **Implementation**: GenStage pipeline for event processing
- **Benefits**: Predictable timing, easy to debug, scalable

### 2. Entity-Component-System (ECS) Design
- **Entities**: Game objects (players, NPCs, items, rooms)
- **Components**: Data containers (health, inventory, position)
- **Systems**: Behavior logic (combat, movement, AI)
- **Benefits**: Flexible, composable, easy to extend

### 3. Agent-Based Architecture
- **Each game entity is an actor**: Players, NPCs, mobs
- **Independent processing**: Each entity handles its own state
- **Message passing**: Entities communicate via messages
- **Supervision**: OTP supervision trees for fault tolerance

## World Design

### World Structure

#### Zones
- **Definition**: Logical groupings of connected areas
- **Purpose**: Organize content, enable content updates, manage load
- **Implementation**: GenServer with zone supervisor
- **Benefits**: Modular content, easier maintenance, scalability

#### Rooms
- **Definition**: Individual locations within zones
- **Components**: 
  - Position (x, y, z coordinates)
  - Description (text, visual elements)
  - Exits (connections to other rooms)
  - Contents (items, NPCs, players)
- **Implementation**: GenServer with room state

#### Exits
- **Definition**: Connections between rooms
- **Types**: 
  - Standard exits (north, south, east, west, up, down)
  - Special exits (custom names, conditions)
  - Hidden exits (require discovery)
- **Implementation**: Component attached to rooms

### World Generation and Spawning

#### Zone Loading
- **Process**: Zones load from configuration files or databases
- **Supervision**: Each zone has its own supervisor
- **State**: Zones maintain their own entity lists and state

#### Room Spawning
- **Automatic**: Rooms spawn when zones load
- **Dynamic**: New rooms can be created during gameplay
- **Persistence**: Room state persists across server restarts

#### Entity Spawning
- **Players**: Spawn in designated starting areas
- **NPCs**: Spawn based on zone configuration and schedules
- **Mobs**: Spawn based on spawn points and respawn timers
- **Items**: Spawn in rooms, on NPCs, or as loot

## Core Systems

### 1. World Tick System
```
World Tick (3s) → Event Queue → Entity Processing → State Update
```

**Implementation**:
- GenStage producer for world ticks
- GenStage consumers for different entity types
- Synchronized processing across all game entities

### 2. Entity Management
- **Entity Registry**: Global registry of all game entities
- **Component Storage**: Efficient storage and retrieval of entity components
- **System Processing**: Systems process entities with specific components

### 3. Action Planning (AI)
- **Mob AI**: Decision-making for NPCs and monsters
- **Behavior Trees**: Hierarchical decision-making
- **Goal-Oriented**: Mobs pursue specific objectives
- **Reactive**: Respond to player actions and world events

## Technical Implementation

### GenServer Usage
- **World Manager**: Orchestrates world ticks and global state
- **Zone Managers**: Handle zone-specific logic
- **Entity Actors**: Individual game objects
- **System Managers**: Coordinate system processing

### GenStage Usage
- **World Tick Producer**: Generates tick events
- **Event Consumers**: Process different types of game events
- **Load Balancing**: Distribute processing across consumers

### Supervision Strategy
- **World Supervisor**: Top-level supervisor for the entire game
- **Zone Supervisors**: Manage individual zones
- **Entity Supervisors**: Handle entity lifecycles
- **System Supervisors**: Manage game systems

## Next Steps

1. **Define Component Types**: Health, mana, stamina, inventory, etc.
2. **Design System Interfaces**: How systems interact with entities
3. **Plan World Tick Implementation**: GenStage pipeline design
4. **Create Entity Spawning Logic**: How entities come into existence
5. **Design Zone Management**: Zone loading and supervision

## Questions to Resolve

1. **Component Storage**: How to efficiently store and retrieve entity components?
2. **System Processing**: How do systems find and process relevant entities?
3. **World Tick Synchronization**: How to ensure all entities process ticks simultaneously?
4. **Entity Communication**: How do entities communicate across the system?
5. **Persistence**: How to save and restore game state?

---

*This document will be updated as we make design decisions and implement features.*
