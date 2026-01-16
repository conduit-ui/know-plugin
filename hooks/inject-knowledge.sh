#!/usr/bin/env bash
# Session Start Hook - Injects relevant knowledge context
# Called by Claude Code on session start

# Find know CLI
KNOW="${KNOW_CLI:-$(which know 2>/dev/null || echo "$HOME/.config/composer/vendor/bin/know")}"

# Default profile ID (can be overridden via env)
PROFILE_ID="${KNOW_PROFILE_ID:-}"

# Parse input
INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

if [ -z "$CWD" ]; then
    exit 0
fi

# Get repo name from git or directory
REPO=$(cd "$CWD" 2>/dev/null && basename "$(git remote get-url origin 2>/dev/null)" .git 2>/dev/null || basename "$CWD")

# Build context
CONTEXT=""

# Inject profile if configured (strip ANSI codes and table formatting)
if [ -n "$PROFILE_ID" ] && [ -x "$KNOW" ]; then
    PROFILE=$($KNOW show "$PROFILE_ID" 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sed 's/\x1b\[?[0-9]*[a-zA-Z]//g' | grep -v "^[[:space:]]*[┌├└│─┬┴┼┐┤┘⠂]" | grep -v "Fetching" | grep -v "^ID:" | grep -v "^$" | head -20)
    if [ -n "$PROFILE" ]; then
        CONTEXT+="## Who You're Talking To"$'\n'"$PROFILE"$'\n\n'
    fi
fi

# Get open issues from vision repo if configured
VISION_REPO="${KNOW_VISION_REPO:-}"
if [ -n "$VISION_REPO" ]; then
    ISSUES=$(gh issue list --repo "$VISION_REPO" --limit=5 --state=open 2>/dev/null | awk -F'\t' '{print "- #"$1": "$3}')
    if [ -n "$ISSUES" ]; then
        CONTEXT+="## Vision Backlog (Open Issues)"$'\n'"$ISSUES"$'\n\n'
    fi
fi

# Get repo-specific entries via semantic search
if [ -x "$KNOW" ]; then
    REPO_ENTRIES=$($KNOW search --semantic "$REPO" --limit=3 2>/dev/null | grep -E "^\[" | head -3)
    if [ -n "$REPO_ENTRIES" ]; then
        CONTEXT+="## Project: $REPO"$'\n'"$REPO_ENTRIES"$'\n\n'
    fi

    # Get active blockers
    BLOCKERS=$($KNOW search --semantic "active blockers stuck waiting" --limit=3 2>/dev/null | grep -E "^\[" | head -3)
    if [ -n "$BLOCKERS" ]; then
        CONTEXT+="## Active Blockers"$'\n'"$BLOCKERS"$'\n\n'
    fi
fi

# Output context directly - Claude Code will inject this
if [ -n "$CONTEXT" ]; then
    echo "<knowledge-context>"
    echo "$CONTEXT"
    echo "</knowledge-context>"
fi

exit 0
