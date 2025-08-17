# Devlog Structure

## Overview

The `.plan` folder contains our daily development log entries, formatted as a series of tweets for easy reading and sharing. Each day gets its own markdown file, tracking our progress, decisions, and next steps.

## File Naming Convention

- **Format**: `YYYY-MM-DD.md`
- **Example**: `2025-08-16.md` for August 16, 2025

## Devlog Format

Each devlog entry follows this structure:

### Header
- Date and project status
- Clear title for the day's work

### Tweet-Style Updates
- **Emoji + Bold Title**: Each "tweet" starts with a relevant emoji and bold title
- **Content**: Concise description of work, decisions, or progress
- **Hashtags**: Relevant tags for easy categorization
- **Separators**: `---` between each "tweet" for readability

### Footer
- **Status**: Current project status
- **Next**: What's planned for next
- **Mood**: How we're feeling about the project

## Example Entry

```markdown
# Devlog - 2025-08-16

## 🚀 Project Kickoff

🎯 **Starting a MUD revival project in Elixir!** 

Why Elixir? Actor model + GenServer + GenStage = perfect fit for distributed game entities. #Elixir #MUD #GameDev

---

🏗️ **Architecture decision: Entity-Component-System (ECS) + Actor model**

Every game object is a GenServer, but behaviors are composed via components. #ECS #ActorModel

---

**Status**: Design phase complete, ready to start implementation
**Next**: Core supervision tree and World Manager
**Mood**: Excited to see this come together! 🎉
```

## Benefits of Tweet Format

1. **Concise**: Forces us to be clear and focused
2. **Shareable**: Easy to share individual updates
3. **Scannable**: Quick to read and understand
4. **Trackable**: Clear progress markers
5. **Engaging**: Visual and fun to read

## When to Update

- **Daily**: At the end of each development session
- **Milestones**: When major features are completed
- **Decisions**: When important architectural decisions are made
- **Challenges**: When we hit roadblocks or solve problems

## Hashtag Categories

- **#Elixir** - Elixir-specific content
- **#MUD** - MUD game design
- **#GameDev** - General game development
- **#Architecture** - System design decisions
- **#Implementation** - Coding progress
- **#OTP** - OTP and supervision topics
- **#Phoenix** - Web interface work
- **#Performance** - Performance considerations

---

*This devlog keeps our progress visible and our decisions documented as we build the MUD engine.*
