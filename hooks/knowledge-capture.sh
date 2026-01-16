#!/usr/bin/env bash
# Knowledge Hook: Capture + Whisper
# 1. Captures milestones, decisions, blockers from user messages
# 2. Semantic search whispers relevant knowledge on every message

# Find know CLI
KNOW="${KNOW_CLI:-$(which know 2>/dev/null || echo "$HOME/.config/composer/vendor/bin/know")}"
LOG="${KNOW_LOG:-$HOME/.claude/hooks/knowledge-capture.log}"

# Skip if know not available
if [ ! -x "$KNOW" ]; then
    exit 0
fi

# Parse input from stdin
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
PROJECT=$(basename "$CWD" 2>/dev/null || echo "unknown")

# Skip empty or very short prompts
if [ -z "$PROMPT" ] || [ ${#PROMPT} -lt 10 ]; then
    exit 0
fi

# Lowercase for matching
LOWER=$(echo "$PROMPT" | tr "[:upper:]" "[:lower:]")

# ============ CAPTURE PHASE ============
CAPTURED=""

# Milestone patterns
if echo "$LOWER" | grep -qE "(tests? pass|all green|coverage|pr merged|deployed|released|feature complete|finished|done with|working now|fixed|resolved)"; then
    TITLE=$(echo "$PROMPT" | head -c 100)
    $KNOW add "Milestone: $TITLE" \
        --category="architecture" \
        --tags="milestone,auto-captured,$PROJECT,$(date +%Y-%m-%d)" \
        --priority="high" \
        --status="validated" \
        --content="Auto-captured from Claude Code session. Project: $PROJECT" \
        2>/dev/null || true
    echo "[$(date)] MILESTONE [$PROJECT]: $PROMPT" >> "$LOG"
    CAPTURED="milestone"
fi

# Decision patterns
if echo "$LOWER" | grep -qE "(lets go with|decided on|choosing|going to use|switching to|instead of|better approach|makes more sense)"; then
    TITLE=$(echo "$PROMPT" | head -c 100)
    $KNOW add "Decision: $TITLE" \
        --category="architecture" \
        --tags="decision,auto-captured,$PROJECT,$(date +%Y-%m-%d)" \
        --priority="high" \
        --content="Auto-captured from Claude Code session. Project: $PROJECT" \
        2>/dev/null || true
    echo "[$(date)] DECISION [$PROJECT]: $PROMPT" >> "$LOG"
    CAPTURED="decision"
fi

# Blocker patterns
if echo "$LOWER" | grep -qE "(blocked by|cant proceed|stuck on|waiting for|depends on)"; then
    TITLE=$(echo "$PROMPT" | head -c 100)
    $KNOW add "Blocker: $TITLE" \
        --category="debugging" \
        --tags="blocker,auto-captured,$PROJECT,$(date +%Y-%m-%d)" \
        --priority="critical" \
        --status="draft" \
        --content="Auto-captured from Claude Code session. Project: $PROJECT" \
        2>/dev/null || true
    echo "[$(date)] BLOCKER [$PROJECT]: $PROMPT" >> "$LOG"
    CAPTURED="blocker"
fi

# ============ WHISPER PHASE ============
# Use semantic search on the full prompt for better relevance
WHISPER=""

# Semantic search with the user's prompt (truncate to 200 chars for query)
QUERY=$(echo "$PROMPT" | head -c 200)
RESULTS=$($KNOW search --semantic "$QUERY" --limit=3 2>/dev/null | tail -n +3)

# Process each entry block
while IFS= read -r line; do
    # Title line (starts with [)
    if [[ "$line" =~ ^\[([a-f0-9-]+)\] ]]; then
        WHISPER+="$line"$'\n'
    # Content snippet lines (not Category/Tags metadata)
    elif [[ -n "$line" && ! "$line" =~ ^(Category:|Tags:|Found) ]]; then
        WHISPER+="  ↳ $line"$'\n'
    fi
done <<< "$RESULTS"

# Output whisper if we found anything
if [ -n "$WHISPER" ]; then
    WHISPER=$(echo "$WHISPER" | head -15)
    echo "<knowledge-whisper>"
    echo "$WHISPER"
    echo "</knowledge-whisper>"
fi

exit 0
