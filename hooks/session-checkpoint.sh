#!/usr/bin/env bash
# session-checkpoint.sh - SessionEnd and PreCompact hook
# Creates session checkpoints and syncs knowledge to cloud

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || source "$HOME/.claude/hooks/common.sh" 2>/dev/null

KNOW=$(find_know_cli)
CWD=$(pwd)
PROJECT=$(get_project_name "$CWD")
BRANCH=$(get_git_branch "$CWD")
MACHINE=$(get_machine_id)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TODAY=$(date +%Y-%m-%d)

# Create handoffs directory
HANDOFF_DIR="$HOME/.claude/handoffs"
mkdir -p "$HANDOFF_DIR" 2>/dev/null

# Parse input
INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && INPUT="{}"
SESSION_ID=$(parse_hook_input "$INPUT" "session_id")
SESSION_ID="${SESSION_ID:-unknown}"

# Get git status
GIT_STATUS=""
if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    MODIFIED_COUNT=$(git -C "$CWD" status --short 2>/dev/null | wc -l | tr -d ' ')
    RECENT_COMMITS=$(git -C "$CWD" log --oneline -5 2>/dev/null)
    GIT_STATUS="Modified files: $MODIFIED_COUNT
Recent commits:
$RECENT_COMMITS"
fi

# Get today's captured knowledge
TODAYS_KNOWLEDGE=""
if [ -n "$KNOW" ]; then
    TODAYS_KNOWLEDGE=$(run_know "$KNOW" search "$TODAY" --tags="auto-captured" --limit=10 2>/dev/null | grep -v "^Found" | head -20)
fi

# Create handoff file
HANDOFF_FILE="$HANDOFF_DIR/${TODAY}_${SESSION_ID:0:8}.md"
cat > "$HANDOFF_FILE" << EOF
---
session_id: $SESSION_ID
timestamp: $TIMESTAMP
machine: $MACHINE
project: $PROJECT
branch: $BRANCH
---

# Session Checkpoint: $PROJECT

**Time**: $TIMESTAMP
**Machine**: $MACHINE
**Branch**: $BRANCH

## Git Status

$GIT_STATUS

## Knowledge Captured This Session

$TODAYS_KNOWLEDGE
EOF

log_hook "session-checkpoint" "Created checkpoint for $PROJECT ($SESSION_ID)"

# Cloud sync if configured
if [ -n "$PREFRONTAL_API_TOKEN" ] && [ -n "$KNOW" ]; then
    (run_know "$KNOW" sync --push && log_hook "session-checkpoint" "Synced to cloud") &
fi

exit 0
