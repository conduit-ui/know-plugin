#!/usr/bin/env bash
# common.sh - Shared utilities for know-plugin hooks
# Portable across all machines (Odin, Mac, work PC, Loki)

set +e  # Don't exit on errors

# Find know CLI using portable detection
find_know_cli() {
    local KNOW=""

    # 1. Environment override (highest priority)
    if [ -n "$KNOW_CLI" ]; then
        echo "$KNOW_CLI"
        return 0
    fi

    # 2. Check if 'know' is in PATH
    KNOW=$(command -v know 2>/dev/null)
    if [ -n "$KNOW" ] && [ -x "$KNOW" ]; then
        echo "$KNOW"
        return 0
    fi

    # 3. Composer global install
    if [ -x "$HOME/.config/composer/vendor/bin/know" ]; then
        echo "$HOME/.config/composer/vendor/bin/know"
        return 0
    fi

    # 4. Local bin symlink
    if [ -x "$HOME/.local/bin/know" ]; then
        echo "$HOME/.local/bin/know"
        return 0
    fi

    # 5. Known development locations
    if [ -x "$HOME/packages/conduit-ui/knowledge/know" ]; then
        echo "$HOME/packages/conduit-ui/knowledge/know"
        return 0
    fi

    if [ -x "$HOME/projects/knowledge/know" ]; then
        echo "$HOME/projects/knowledge/know"
        return 0
    fi

    return 1
}

# Get project name from cwd (no side effects)
get_project_name() {
    local CWD="${1:-$(pwd)}"
    local REMOTE

    REMOTE=$(git -C "$CWD" remote get-url origin 2>/dev/null)
    if [ -n "$REMOTE" ]; then
        basename "$REMOTE" .git 2>/dev/null
        return 0
    fi

    basename "$CWD" 2>/dev/null || echo "unknown"
}

# Get current git branch (no side effects)
get_git_branch() {
    local CWD="${1:-$(pwd)}"
    git -C "$CWD" branch --show-current 2>/dev/null || echo ""
}

# Run know command safely
run_know() {
    local KNOW="$1"
    shift
    [ -z "$KNOW" ] && return 1
    "$KNOW" "$@" 2>/dev/null
}

# Log to hook log file
log_hook() {
    local HOOK_NAME="$1"
    local MESSAGE="$2"
    local LOG_FILE="$HOME/.claude/hooks/${HOOK_NAME}.log"
    mkdir -p "$HOME/.claude/hooks" 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE" >> "$LOG_FILE"
}

# Parse JSON input from Claude hooks
parse_hook_input() {
    local INPUT="$1"
    local FIELD="$2"
    echo "$INPUT" | jq -r ".$FIELD // \"\"" 2>/dev/null
}

# Get machine identifier
get_machine_id() {
    hostname -s 2>/dev/null || echo "unknown"
}
