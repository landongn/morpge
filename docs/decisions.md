# Design Decision Log

## 2025-08-16 - Project Initialization

### Decision: Use Elixir for MUD Engine
**Status**: ✅ Decided
**Rationale**: 
- Actor model naturally fits game entities
- GenServer provides stateful game objects
- GenStage handles world ticks and events
- OTP gives built-in supervision and fault tolerance
- Phoenix enables modern web interface

**Alternatives Considered**: 
- Node.js (event-driven but less actor-oriented)
- Rust (performance but more complex concurrency)
- Go (good concurrency but less actor-focused)

### Decision: 3-Second World Tick Frequency
**Status**: ✅ Decided
**Rationale**:
- Provides responsive gameplay without overwhelming the system
- Allows for meaningful regeneration rates (e.g., 1-5% per tick)
- Balances performance with game feel
- Easy to adjust if needed

**Alternatives Considered**:
- 1 second (too fast, might overwhelm)
- 5 seconds (too slow, feels sluggish)

### Decision: Entity-Component-System (ECS) Architecture
**Status**: ✅ Decided
**Rationale**:
- Flexible composition of game objects
- Easy to add new behaviors
- Separates data from logic
- Natural fit with Elixir's functional approach

**Alternatives Considered**:
- Traditional OOP inheritance
- Pure functional approach
- Data-oriented design

### Decision: GenStage for World Tick Processing
**Status**: ✅ Decided
**Rationale**:
- Built-in backpressure handling
- Easy to scale with multiple consumers
- Natural pipeline for game events
- OTP integration

**Alternatives Considered**:
- Custom timer-based approach
- PubSub with Phoenix
- Direct GenServer calls

### Decision: Zone-Based World Organization
**Status**: ✅ Decided
**Rationale**:
- Modular content management
- Easier to update and maintain
- Better scalability
- Natural supervision boundaries

**Alternates Considered**:
- Single large world
- Room-based organization
- Grid-based organization

## Pending Decisions

### Component Storage Strategy
**Status**: 🔄 Pending
**Options**:
1. Map-based storage in GenServer state
2. ETS tables for fast access
3. Database-backed storage
4. Hybrid approach

**Considerations**:
- Performance requirements
- Memory usage
- Persistence needs
- Query complexity

### Entity Communication Pattern
**Status**: 🔄 Pending
**Options**:
1. Direct GenServer calls
2. Message passing via registry
3. Event-driven system
4. Hybrid approach

**Considerations**:
- Coupling between entities
- Performance impact
- Debugging complexity
- Scalability

### World Tick Synchronization
**Status**: 🔄 Pending
**Options**:
1. Global synchronized ticks
2. Zone-based ticks
3. Entity-based ticks
4. Hybrid approach

**Considerations**:
- Consistency requirements
- Performance impact
- Complexity of implementation
- Debugging ease

## 2025-08-16 - Entity System Design

### Decision: Every Entity is a GenServer
**Status**: ✅ Decided
**Rationale**: 
- Natural fault isolation through OTP supervision
- Independent state management for each entity
- Easy to supervise and restart
- Perfect fit with Elixir's actor model

**Alternatives Considered**: 
- Single GenServer managing all entities (poor fault isolation)
- Pure functional approach (no state persistence)
- Database-backed entities (poor performance, complex state management)

### Decision: Component-Based Behavior System
**Status**: ✅ Decided
**Rationale**:
- Flexible composition of entity behaviors
- Easy to add/remove capabilities dynamically
- Clear separation of concerns
- Natural fit with GenServer state management

**Alternatives Considered**:
- Inheritance-based approach (less flexible, harder to extend)
- Pure functional components (complex state management)
- Event-driven behaviors (harder to debug, more complex)

### Decision: Multi-Level Supervision Tree
**Status**: ✅ Decided
**Rationale**:
- Perfect fault isolation between entity types
- Different restart strategies for different entity types
- Easy to scale and manage
- Natural OTP supervision patterns

**Alternatives Considered**:
- Single supervisor for all entities (poor fault isolation)
- Flat supervision structure (harder to manage)
- Custom supervision logic (reinventing OTP)

### Decision: Centralized Entity Registry with Indexing
**Status**: ✅ Decided
**Rationale**:
- Fast entity lookups by various criteria
- Centralized entity lifecycle management
- Easy to query and filter entities
- Performance through smart indexing

**Alternatives Considered**:
- Distributed entity tracking (complex, hard to maintain)
- Database-only entity storage (poor performance)
- No central registry (hard to manage, poor performance)

### Decision: Rule-Based Spawning System
**Status**: ✅ Decided
**Rationale**:
- Configurable without code changes
- Data-driven entity creation
- Easy to modify spawn behaviors
- Supports complex spawn conditions

**Alternatives Considered**:
- Hard-coded spawning logic (not flexible)
- Simple random spawning (no control)
- Manual entity creation only (not scalable)

## 2025-01-XX - Layered World System Design

### Decision: ASCII-Based Map Representation
**Status**: ✅ Decided
**Rationale**:
- Human-readable and debuggable
- Easy to edit manually or programmatically
- Compact storage format
- Natural fit with text-based MUD interface
- Can represent complex spatial relationships with simple characters

**Alternatives Considered**:
- Binary map format (harder to debug, edit)
- JSON-based maps (more verbose, harder to visualize)
- Vector-based coordinates (complex for tile-based systems)

### Decision: Minimal Core Layer Set
**Status**: ✅ Decided
**Rationale**:
- Ground: Foundation for all other layers
- Atmosphere: Environmental effects and visibility
- Plants: Dynamic vegetation and resources
- Structures: Buildings and architectural elements
- Floor_plans: Interior layouts and room connections
- Doors: Passageways and zone transitions

**Alternatives Considered**:
- Single monolithic layer (too complex, hard to manage)
- Too many specialized layers (over-engineering)
- Layer-less approach (no spatial organization)

### Decision: Database-First Layer Storage
**Status**: ✅ Decided
**Rationale**:
- Persistent storage across server restarts
- Easy to backup and version control
- Can be edited through admin interfaces
- Supports complex queries and relationships
- Natural fit with Ecto schemas

**Alternatives Considered**:
- File-based storage (harder to manage, no transactions)
- In-memory only (lost on restart)
- Hybrid approach (added complexity)

### Decision: GenServer-Based Layer Management
**Status**: ✅ Decided
**Rationale**:
- Each layer is independently supervised
- Fault isolation between layers
- Easy to add/remove layers dynamically
- Natural OTP patterns for state management
- Can handle complex layer interactions

**Alternatives Considered**:
- Single GenServer for all layers (poor fault isolation)
- Pure functional approach (complex state management)
- Database-only approach (poor performance)

### Decision: Standardized Layer Communication Protocol
**Status**: ✅ Decided
**Rationale**:
- Consistent interface for all layers
- Easy to add new layer types
- Clear separation of concerns
- Supports complex inter-layer interactions
- Natural fit with GenServer message passing

**Alternatives Considered**:
- Custom protocols per layer (inconsistent, hard to maintain)
- Direct function calls (tight coupling)
- Event-driven system (complex debugging)

### Decision: 3-Second World Tick for Layer Processing
**Status**: ✅ Decided
**Rationale**:
- Consistent with existing entity tick system
- Allows for meaningful environmental changes
- Balances performance with responsiveness
- Easy to adjust if needed

**Alternatives Considered**:
- Different tick rates per layer (complex synchronization)
- Continuous processing (resource intensive)
- Manual triggering only (not automated)

### Decision: Top-Down 2D Tile-Based View
**Status**: ✅ Decided
**Rationale**:
- Natural fit with ASCII map representation
- Easy to implement and understand
- Good performance for large worlds
- Familiar to players from traditional MUDs
- Supports complex spatial relationships

**Alternatives Considered**:
- 3D view (complex, resource intensive)
- Isometric view (harder to implement)
- Text-only description (no visual reference)

---

*This log tracks all major design decisions and their rationale.*
