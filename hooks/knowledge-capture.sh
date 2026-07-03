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

# ============ CAPTURE PHASE (classify-gated when hird is available) ============
# Keyword regex is a cheap prefilter; where hird (local-model classifier) exists,
# it decides whether the message is actually a milestone/decision/blocker vs a
# question or noise. Everything stores as DRAFT so cleanup crons retain veto.
# Classification runs detached: the hook returns fast, inference can take a minute.
CAPTURE_RE="(tests? pass|all green|coverage|pr merged|deployed|released|feature complete|finished|done with|working now|fixed|resolved)"
DECISION_RE="(lets go with|decided on|choosing|going to use|switching to|instead of|better approach|makes more sense)"
BLOCKER_RE="(blocked by|cant proceed|stuck on|waiting for|depends on)"
HIRD="${HIRD_BIN:-$HOME/.local/bin/hird}"

store_capture() {
    # $1=label $2=category $3=priority
    "$KNOW" add "${1^}: $(printf '%s' "$PROMPT" | head -c 100)" \
        --category="$2" \
        --tags="$1,auto-captured,$PROJECT,$(date +%Y-%m-%d)" \
        --priority="$3" \
        --status="draft" \
        --content="Auto-captured from Claude Code session. Project: $PROJECT. Prompt: $(printf '%s' "$PROMPT" | head -c 500)" \
        2>/dev/null || true
    echo "[$(date)] CAPTURED as $1 [$PROJECT]: $(printf '%s' "$PROMPT" | head -c 120)" >> "$LOG"
}

if echo "$LOWER" | grep -qE "$CAPTURE_RE|$DECISION_RE|$BLOCKER_RE"; then
    if [ -x "$HIRD" ]; then
        # hird gate: local model classifies; only real signal is stored (as draft)
        export -f store_capture
        export PROMPT PROJECT KNOW LOG HIRD
        setsid bash -c '
            LABEL=$(printf "%s" "$PROMPT" | "$HIRD" classify "milestone,decision,blocker,question,noise" 2>/dev/null \
                    | tr -d "[:space:]" | tr "[:upper:]" "[:lower:]")
            case "$LABEL" in
                milestone|decision) store_capture "$LABEL" "architecture" "high" ;;
                blocker)            store_capture "blocker" "debugging" "critical" ;;
                *) echo "[$(date)] SKIPPED (hird: ${LABEL:-no-answer}) [$PROJECT]: $(printf "%s" "$PROMPT" | head -c 120)" >> "$LOG" ;;
            esac
        ' >/dev/null 2>&1 &
    else
        # No hird on this machine: regex-only capture, demoted to draft
        if echo "$LOWER" | grep -qE "$BLOCKER_RE"; then
            store_capture "blocker" "debugging" "critical"
        elif echo "$LOWER" | grep -qE "$DECISION_RE"; then
            store_capture "decision" "architecture" "high"
        else
            store_capture "milestone" "architecture" "high"
        fi
    fi
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
    echo "[$(date '+%A %I:%M%p %Z %Y-%m-%d')]"
    echo "$WHISPER"
    echo "</knowledge-whisper>"
fi

exit 0
