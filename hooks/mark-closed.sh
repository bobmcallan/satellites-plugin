#!/usr/bin/env bash
# Satellites Guard — PostToolUse hook for satellites_reviewer_submit
# Clears the manifest marker when a session is closed with an outcome.

PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-.claude}"
MARKER="$PLUGIN_DATA/.satellites-manifest"
MARKER_VALID_CACHE="$PLUGIN_DATA/.satellites-marker-valid"

INPUT=$(cat)

if echo "$INPUT" | grep -q '"outcome"'; then
    rm -f "$MARKER" "$MARKER_VALID_CACHE"
fi

exit 0
