#!/usr/bin/env bash
# Satellites Guard — PreToolUse hook for Edit/Write/MultiEdit
# Local-only check: blocks edits when no active manifest marker exists.
# No HTTP calls — sub-millisecond execution.

PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-.claude}"
MARKER="$PLUGIN_DATA/.satellites-manifest"
MARKER_MAX_AGE=14400  # 4 hours

INPUT=$(cat)

# Fast path: marker exists and is not stale
if [ -f "$MARKER" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        MARKER_MTIME=$(stat -f %m "$MARKER" 2>/dev/null || echo 0)
    else
        MARKER_MTIME=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0)
    fi
    NOW=$(date +%s)
    AGE=$(( NOW - MARKER_MTIME ))
    if [ "$AGE" -le "$MARKER_MAX_AGE" ]; then
        exit 0
    fi
    rm -f "$MARKER"
fi

# Always allow .claude/ paths (tooling config, not source code)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')
if [ -n "$FILE_PATH" ]; then
    case "$FILE_PATH" in
        */.claude/*|.claude/*) exit 0 ;;
    esac
fi

echo '{"decision":"deny","reason":"No active manifest. Call satellites_acquire_context before editing code."}' >&2
exit 2
