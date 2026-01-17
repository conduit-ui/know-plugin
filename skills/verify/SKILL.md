---
name: know:verify
description: Verify know-plugin installation and show health status
---

# Know Plugin Verification

Quick health check for whisper loop installation.

## Run Verification

```bash
~/.claude/hooks/verify.sh
```

## What Gets Checked

1. **Know CLI** - Is the know command available?
2. **Hook Scripts** - Are all 5 hooks installed and executable?
3. **Settings** - Is settings.json configured with hooks?
4. **Environment** - Is cloud sync configured?
5. **Knowledge Base** - How many entries exist locally?

## Expected Output

```
============================================
  Know Plugin Verification
============================================

Machine: your-machine

1. Know CLI
   [OK] Found: /path/to/know

2. Hook Scripts
   [OK] common.sh
   [OK] inject-knowledge.sh
   [OK] knowledge-capture.sh
   [OK] session-checkpoint.sh

3. Settings
   [OK] Hooks: SessionStart, UserPromptSubmit, SessionEnd, PreCompact

4. Environment
   [OK] Cloud sync enabled

5. Knowledge Base
   [OK] 1234 entries

============================================
  Passed: 9 | Failed: 0 | Warned: 0
============================================
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Know CLI not found | `composer global require conduit-ui/knowledge` |
| Hook missing | Re-run `/know:install` |
| Cloud sync disabled | Set `PREFRONTAL_API_TOKEN` in `~/.zshrc` |
| Settings missing | Check `~/.claude/settings.json` |

## Manual Checks

```bash
# Check know version
know --version

# Check local entry count
know stats

# Test semantic search
know search "test query" --semantic --limit=1
```
