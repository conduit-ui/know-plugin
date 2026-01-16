# Know Plugin

Claude Code plugin for Conduit knowledge management - capture and retrieve technical insights, patterns, and decisions.

## Installation

```bash
/plugins install know@conduit-ui-marketplace
```

## Requirements

- [Conduit CLI](https://github.com/conduit-ui/conduit-ui) with the `knowledge` component installed

```bash
conduit component:install knowledge
```

## Agents

### knowledge-bridge

**Purpose**: Capture technical insights and preserve them for future reference.

**Triggers automatically when**:
- Bug solutions are discovered
- Architectural decisions are made
- Reusable patterns are identified
- Performance optimizations are found

**Example**:
```
User: "I figured out the issue - the service provider wasn't being registered in the correct order."
Claude: Uses knowledge-bridge to capture the insight with appropriate tags
```

### knowledge-retriever

**Purpose**: Query the knowledge base to resolve confusion or find established patterns.

**Use when**:
- Uncertain about project-specific conventions
- Need to find documented patterns
- Looking for previous solutions to similar problems

**Example**:
```
User: "How do we handle authentication in this project?"
Claude: Uses knowledge-retriever to search for established auth patterns
```

## Hooks (Automatic Knowledge Loop)

In addition to agents, this plugin includes hooks for automatic knowledge injection and capture.

### Installation

```bash
# After installing the plugin, set up hooks:
./hooks/install.sh
```

### What the Hooks Do

| Hook | Event | Purpose |
|------|-------|---------|
| `inject-knowledge.sh` | SessionStart | Injects profile, project context, blockers at session start |
| `knowledge-capture.sh` | UserPromptSubmit | Captures milestones/decisions/blockers + semantic whispers |

### The Knowledge Whisper Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    THE WHISPER LOOP                         │
├─────────────────────────────────────────────────────────────┤
│  You type → [UserPromptSubmit hook]                         │
│                    ↓                                        │
│            ┌──────────────────┐                             │
│            │ CAPTURE          │                             │
│            │ • milestones     │ → know add                  │
│            │ • decisions      │                             │
│            │ • blockers       │                             │
│            └──────────────────┘                             │
│                    ↓                                        │
│            ┌──────────────────┐                             │
│            │ WHISPER          │                             │
│            │ • semantic search│ → know search --semantic    │
│            │ • inject context │ → <knowledge-whisper>       │
│            └──────────────────┘                             │
│                    ↓                                        │
│              Claude responds with full context              │
└─────────────────────────────────────────────────────────────┘
```

### Configuration

Set these environment variables for full functionality:

```bash
# Profile ID for session briefing (find with: know entries | grep -i profile)
export KNOW_PROFILE_ID="your-profile-entry-id"

# Vision repo for backlog injection
export KNOW_VISION_REPO="yourorg/vision"
```

## How It Works

```
┌─────────────────┐     ┌──────────────────┐
│ knowledge-bridge│────▶│ conduit          │
│ (capture)       │     │ knowledge:add    │
└─────────────────┘     └──────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │ Knowledge Base   │
                        │ (SQLite/Postgres)│
                        └──────────────────┘
                               ▲
                               │
┌─────────────────┐     ┌──────────────────┐
│knowledge-retriever────▶│ conduit          │
│ (query)         │     │ knowledge:search │
└─────────────────┘     └──────────────────┘
```

## Tag Taxonomy

When capturing knowledge, use these tag categories:

| Category | Values |
|----------|--------|
| **Type** | bug, fix, feature, pattern, decision, insight, workaround, optimization |
| **Component** | conduit-core, github-component, or specific component names |
| **Architecture** | laravel-zero, service-provider, command-pattern, dependency-injection |
| **Context** | root-cause, solution, performance, security, technical-debt |

## Related

- [conduit-ui/know](https://github.com/conduit-ui/know) - PHP library for structured knowledge storage
- [Conduit UI](https://github.com/conduit-ui/conduit-ui) - Main CLI tool

## License

MIT
