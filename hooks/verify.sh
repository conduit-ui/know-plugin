#!/usr/bin/env bash
# verify.sh - Verify know-plugin installation

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || source "$HOME/.claude/hooks/common.sh" 2>/dev/null

MACHINE=$(get_machine_id)
PASSED=0
FAILED=0
WARNED=0

echo "============================================"
echo "  Know Plugin Verification"
echo "============================================"
echo ""
echo "Machine: $MACHINE"
echo ""

# 1. Check know CLI
echo "1. Know CLI"
KNOW=$(find_know_cli)
if [ -n "$KNOW" ]; then
    echo "   [OK] Found: $KNOW"
    ((PASSED++))
else
    echo "   [FAIL] Not found"
    ((FAILED++))
fi
echo ""

# 2. Check hook scripts
echo "2. Hook Scripts"
for hook in common.sh inject-knowledge.sh knowledge-capture.sh session-checkpoint.sh; do
    if [ -x "$HOME/.claude/hooks/$hook" ]; then
        echo "   [OK] $hook"
        ((PASSED++))
    else
        echo "   [WARN] $hook missing"
        ((WARNED++))
    fi
done
echo ""

# 3. Check settings.json
echo "3. Settings"
if [ -f "$HOME/.claude/settings.json" ]; then
    HOOKS=$(jq -r '.hooks | keys | join(", ")' "$HOME/.claude/settings.json" 2>/dev/null)
    echo "   [OK] Hooks: $HOOKS"
    ((PASSED++))
else
    echo "   [FAIL] settings.json missing"
    ((FAILED++))
fi
echo ""

# 4. Check environment
echo "4. Environment"
if [ -n "$PREFRONTAL_API_TOKEN" ]; then
    echo "   [OK] Cloud sync enabled"
    ((PASSED++))
else
    echo "   [WARN] Cloud sync disabled (no PREFRONTAL_API_TOKEN)"
    ((WARNED++))
fi
echo ""

# 5. Knowledge stats
echo "5. Knowledge Base"
if [ -n "$KNOW" ]; then
    COUNT=$(run_know "$KNOW" stats 2>/dev/null | grep -oE "[0-9]+ entries" | head -1)
    echo "   [OK] $COUNT"
    ((PASSED++))
fi
echo ""

echo "============================================"
echo "  Passed: $PASSED | Failed: $FAILED | Warned: $WARNED"
echo "============================================"

[ $FAILED -eq 0 ] && exit 0 || exit 1
