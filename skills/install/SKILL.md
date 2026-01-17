---
name: know:install
description: Install know-plugin whisper loop hooks on current machine
---

# Know Plugin Installation

One-command setup for the portable whisper loop.

## Quick Install

Run the installer:

```bash
~/.claude/plugins/cache/*/know/*/hooks/install.sh
```

Or if you have the repo cloned:

```bash
~/packages/know-plugin/hooks/install.sh
```

## What Gets Installed

| Hook | Event | Purpose |
|------|-------|---------|
| `common.sh` | Shared | Portable CLI detection |
| `inject-knowledge.sh` | SessionStart | Context injection |
| `knowledge-capture.sh` | UserPromptSubmit | Auto-capture + whisper |
| `session-checkpoint.sh` | SessionEnd/PreCompact | Handoff + cloud sync |
| `verify.sh` | Manual | Verify installation |

## Post-Install Configuration

Add to `~/.zshrc`:

```bash
# Profile injection (optional)
export KNOW_PROFILE_ID='your-profile-id'

# Cloud sync (required for cross-machine sync)
export PREFRONTAL_API_TOKEN='your-token'
```

## Verify Installation

After install, run:

```bash
~/.claude/hooks/verify.sh
```

## Troubleshooting

**Know CLI not found?**
```bash
# Check if know is installed
which know

# Or install via composer
composer global require conduit-ui/knowledge
```

**Hooks not running?**
- Restart Claude Code after installation
- Check `~/.claude/settings.json` for hooks configuration
