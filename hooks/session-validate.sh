#!/usr/bin/env bash
# Satellites Guard — UserPromptSubmit hook
# Validates manifest marker on every prompt. If stale or closed, injects
# a reminder so Claude knows to call acquire_context before any work.

PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-.claude}"
MARKER="$PLUGIN_DATA/.satellites-manifest"
MARKER_VALID_CACHE="$PLUGIN_DATA/.satellites-marker-valid"
ENFORCE_URL="${SATELLITES_URL%/mcp}/api/enforce"
MARKER_MAX_AGE=14400  # 4 hours

is_marker_valid() {
    [ -f "$MARKER" ] || return 1

    if [ "$(uname)" = "Darwin" ]; then
        MARKER_MTIME=$(stat -f %m "$MARKER" 2>/dev/null || echo 0)
    else
        MARKER_MTIME=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE=$(( NOW - MARKER_MTIME ))
    if [ "$AGE" -gt "$MARKER_MAX_AGE" ]; then
        rm -f "$MARKER" "$MARKER_VALID_CACHE"
        return 1
    fi

    if [ -f "$MARKER_VALID_CACHE" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            CACHE_MTIME=$(stat -f %m "$MARKER_VALID_CACHE" 2>/dev/null || echo 0)
        else
            CACHE_MTIME=$(stat -c %Y "$MARKER_VALID_CACHE" 2>/dev/null || echo 0)
        fi
        CACHE_AGE=$(( NOW - CACHE_MTIME ))
        if [ "$CACHE_AGE" -lt 60 ]; then return 0; fi
    fi

    MANIFEST_ID=$(cat "$MARKER")
    RESPONSE=$(curl -s --max-time 2 -X POST "$ENFORCE_URL" \
        -H "Content-Type: application/json" \
        -d "{\"tool_name\":\"validate_marker\",\"manifest_id\":\"${MANIFEST_ID}\",\"has_manifest\":true}" 2>/dev/null)

    if [ -z "$RESPONSE" ]; then
        touch "$MARKER_VALID_CACHE"
        return 0
    fi

    DECISION=$(echo "$RESPONSE" | grep -o '"decision":"[^"]*"' | head -1 | sed 's/"decision":"//;s/"//')
    if [ "$DECISION" = "deny" ]; then
        rm -f "$MARKER" "$MARKER_VALID_CACHE"
        return 1
    fi

    touch "$MARKER_VALID_CACHE"
    return 0
}

if is_marker_valid; then
    MANIFEST_ID=$(cat "$MARKER")
    echo "Active manifest: ${MANIFEST_ID}" >&2
    exit 0
fi

echo "No active Satellites manifest. You MUST call satellites_acquire_context before doing any work in this session. All sessions require manifest tracking." >&2
exit 0
