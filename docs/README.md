# MUD Revival Project Documentation

Welcome to the documentation for our Elixir-based MUD revival project! This folder contains all the design decisions, technical specifications, and implementation details for building a modern, scalable MUD engine.

## Documentation Structure

### 📋 [mud_design.md](./mud_design.md)
**Purpose**: High-level project overview and design principles
**Contents**:
- Project overview and rationale
- Core architecture principles
- World design concepts
- Core systems overview
- Next steps and questions

**Best for**: Understanding the project vision and high-level architecture

### 📝 [decisions.md](./decisions.md)
**Purpose**: Track all design decisions and their rationale
**Contents**:
- Decided design choices with explanations
- Pending decisions that need resolution
- Alternatives considered for each decision
- Decision status tracking

**Best for**: Understanding why we made specific design choices

### 📅 [.plan/](./.plan/)
**Purpose**: Daily development progress and updates
**Contents**:
- Tweet-style devlog entries organized by date
- Daily progress, decisions, and challenges
- Next steps and project status
- Development mood and milestones

**Best for**: Following our development journey day by day

### 🏗️ [technical_architecture.md](./technical_architecture.md)
**Purpose**: Detailed technical implementation specifications
**Contents**:
- System component breakdowns
- GenStage pipeline designs
- ECS implementation details
- Supervision strategies
- Performance considerations

**Best for**: Developers implementing the system

### 🎮 [entity_system_design.md](./entity_system_design.md)
**Purpose**: Comprehensive entity system architecture and design
**Contents**:
- Entity types and hierarchy
- Supervision architecture
- Entity registry and management
- Spawning system design
- Component system details
- Fault tolerance strategies

**Best for**: Understanding the core entity system architecture

### 🖥️ [liveview_interface_design.md](./liveview_interface_design.md)
**Purpose**: User interface and messaging system design
**Contents**:
- LiveView architecture and structure
- Visual layout and chat box design
- Message types and channels
- Command processing system
- Real-time communication
- User experience considerations

**Best for**: Understanding the user interface and messaging architecture

## Quick Start

1. **Start with** `mud_design.md` to understand the project vision
2. **Check** `decisions.md` to see what's been decided and what's pending
3. **Dive into** `technical_architecture.md` for implementation details

## Contributing to Documentation

When making design decisions or implementing features:

1. **Update** `decisions.md` with new decisions and rationale
2. **Expand** `technical_architecture.md` with implementation details
3. **Keep** `mud_design.md` updated with high-level changes
4. **Add** new documents for specific subsystems as needed

## Key Design Principles

- **Actor-Based**: Every game entity is a GenServer
- **Event-Driven**: GenStage handles world ticks and events
- **Component-Based**: ECS pattern for flexible entity behavior
- **Fault-Tolerant**: OTP supervision for reliability
- **Scalable**: Designed for multi-node distribution

## Current Status

- ✅ **Project Vision**: Defined and documented
- ✅ **Core Architecture**: ECS + Actor model decided
- ✅ **Technology Stack**: Elixir + OTP + Phoenix chosen
- ✅ **Entity System**: Core architecture implemented and tested
- ✅ **Component System**: Health component implemented and tested
- ✅ **User Interface Design**: LiveView interface architecture designed
- ✅ **LiveView Implementation**: Complete interface implemented and tested
- 🔄 **Integration**: Ready to connect UI with entity system
- 🔄 **Component Design**: Additional components (Mana, Stamina, etc.) pending

---

*This documentation will evolve as we implement and refine the system.*
