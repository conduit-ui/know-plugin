#!/usr/bin/env bash
# Install know-plugin hooks for Claude Code
# Sets up automatic knowledge injection and capture

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "Installing know-plugin hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Copy hook scripts
cp "$SCRIPT_DIR/inject-knowledge.sh" "$HOOKS_DIR/"
cp "$SCRIPT_DIR/knowledge-capture.sh" "$HOOKS_DIR/"
chmod +x "$HOOKS_DIR/inject-knowledge.sh"
chmod +x "$HOOKS_DIR/knowledge-capture.sh"

echo "✓ Copied hooks to $HOOKS_DIR"

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Creating $SETTINGS_FILE..."
    echo '{"$schema": "https://json.schemastore.org/claude-code-settings.json", "hooks": {}}' > "$SETTINGS_FILE"
fi

# Backup existing settings
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

# Update settings.json with hooks configuration using jq
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
  }]
}'

# Merge hooks config into settings
if command -v jq &> /dev/null; then
    jq --argjson hooks "$HOOKS_CONFIG" '.hooks = ($hooks * .hooks)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "✓ Updated $SETTINGS_FILE with hooks configuration"
else
    echo "⚠ jq not found - please manually add hooks to $SETTINGS_FILE"
    echo "Hooks config:"
    echo "$HOOKS_CONFIG"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Optional configuration (add to ~/.bashrc or ~/.zshrc):"
echo ""
echo "  # Profile ID for session briefing (find with: know entries | grep -i profile)"
echo "  export KNOW_PROFILE_ID=\"your-profile-entry-id\""
echo ""
echo "  # Vision repo for backlog injection"
echo "  export KNOW_VISION_REPO=\"yourorg/vision\""
echo ""
echo "Restart Claude Code to activate hooks."
