#!/usr/bin/env bash
# Install know-plugin hooks for Claude Code
# Sets up automatic knowledge injection, capture, and sync

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "============================================"
echo "  Know Plugin v2.0 - Whisper Loop Installer"
echo "============================================"
echo ""

# Create directories
mkdir -p "$HOOKS_DIR"
mkdir -p "$CLAUDE_DIR/handoffs"

# Copy all hook scripts
echo "Installing hooks..."
for script in common.sh inject-knowledge.sh knowledge-capture.sh session-checkpoint.sh verify.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        cp "$SCRIPT_DIR/$script" "$HOOKS_DIR/"
        chmod +x "$HOOKS_DIR/$script"
        echo "  [OK] $script"
    fi
done

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{"$schema": "https://json.schemastore.org/claude-code-settings.json", "hooks": {}}' > "$SETTINGS_FILE"
fi

# Backup existing settings
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"

# Full hooks config including SessionEnd and PreCompact
HOOKS_CONFIG='{
  "SessionStart": [{
    "matcher": "startup",
    "hooks": [{
      "type": "command",
      "command": "bash ~/.claude/hooks/inject-knowledge.sh",
      "timeout": 15
    }]
  }],
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "bash ~/.claude/hooks/knowledge-capture.sh",
      "timeout": 10
    }]
  }],
  "SessionEnd": [{
    "hooks": [{
      "type": "command",
      "command": "bash ~/.claude/hooks/session-checkpoint.sh",
      "timeout": 10
    }]
  }],
  "PreCompact": [{
    "matcher": "auto",
    "hooks": [{
      "type": "command",
      "command": "bash ~/.claude/hooks/session-checkpoint.sh",
      "timeout": 10
    }]
  }]
}'

# Merge hooks config
if command -v jq &> /dev/null; then
    jq --argjson hooks "$HOOKS_CONFIG" '.hooks = ($hooks * .hooks)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo ""
    echo "  [OK] Configured hooks in settings.json"
else
    echo ""
    echo "  [WARN] jq not found - manually add hooks to settings.json"
fi

echo ""
echo "============================================"
echo "  Installation Complete!"
echo "============================================"
echo ""
echo "Optional environment variables:"
echo "  export KNOW_PROFILE_ID='your-profile-id'     # Profile injection"
echo "  export PREFRONTAL_API_TOKEN='your-token'     # Cloud sync"
echo ""
echo "Verify: ~/.claude/hooks/verify.sh"
echo ""
echo "Restart Claude Code to activate."
