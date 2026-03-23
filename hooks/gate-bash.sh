#!/usr/bin/env bash
# Satellites Guard — PreToolUse hook for Bash
# Fast-paths safe commands locally. Sends git operations and file-write
# patterns to the server for delivery strategy evaluation.

PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-.claude}"
MARKER="$PLUGIN_DATA/.satellites-manifest"
ENFORCE_URL="${SATELLITES_URL%/mcp}/api/enforce"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"//')

# Detect commands that need server-side evaluation
NEEDS_SERVER=false
case "$COMMAND" in
    *git\ push*|*git\ checkout\ -b*|*git\ switch\ -c*|*git\ branch\ *)
        NEEDS_SERVER=true
        ;;
esac

# File-write patterns: only check when no manifest marker exists
if [ "$NEEDS_SERVER" = "false" ] && [ ! -f "$MARKER" ]; then
    case "$COMMAND" in
        *\>*|*tee\ *|*sed\ -i*|*\<\<*)
            NEEDS_SERVER=true
            ;;
    esac
fi

# Fast path: skip server call for non-git, non-write commands
if [ "$NEEDS_SERVER" = "false" ]; then exit 0; fi

# Server-side check (delivery strategy + file-write enforcement)
MANIFEST_ID=""
HAS_MANIFEST=false
if [ -f "$MARKER" ]; then
    MANIFEST_ID=$(cat "$MARKER")
    HAS_MANIFEST=true
fi

RESPONSE=$(curl -s --max-time 2 -X POST "$ENFORCE_URL" \
    -H "Content-Type: application/json" \
    -d "{\"tool_name\":\"Bash\",\"command\":$(echo "$COMMAND" | sed 's/\\/\\\\/g;s/"/\\"/g;s/.*/\"&\"/'),\"manifest_id\":\"${MANIFEST_ID}\",\"has_manifest\":${HAS_MANIFEST}}" 2>/dev/null)

# Graceful fallback: if server unreachable, allow
if [ -z "$RESPONSE" ]; then exit 0; fi

DECISION=$(echo "$RESPONSE" | grep -o '"decision":"[^"]*"' | head -1 | sed 's/"decision":"//;s/"//')
if [ "$DECISION" = "deny" ]; then
    echo "$RESPONSE" >&2
    exit 2
fi

exit 0
