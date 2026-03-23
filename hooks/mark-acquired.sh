#!/usr/bin/env bash
# Satellites Guard — PostToolUse hook for satellites_acquire_context
# Writes the manifest marker after successful context acquisition.

PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-.claude}"
MARKER="$PLUGIN_DATA/.satellites-manifest"
MARKER_VALID_CACHE="$PLUGIN_DATA/.satellites-marker-valid"

INPUT=$(cat)

MANIFEST_ID=$(echo "$INPUT" | sed 's/\\"/"/g' | grep -o '"manifest_id":"[^"]*"' | head -1 | sed 's/"manifest_id":"//;s/"//')
if [ -n "$MANIFEST_ID" ]; then
    mkdir -p "$PLUGIN_DATA"
    echo "$MANIFEST_ID" > "$MARKER"
    rm -f "$MARKER_VALID_CACHE"
fi

exit 0
