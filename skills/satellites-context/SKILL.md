# Satellites Context Acquisition

## Why You Are Being Blocked

If your Edit, Write, or Bash tool calls are being denied with "No active manifest", it means the `satellites-guard` plugin is enforcing the mandatory context acquisition workflow.

## What To Do

Before any code changes, call:

```
satellites_acquire_context(intent="<what you are doing>", git_remote="<output of git remote get-url origin>")
```

This returns:
- **Matched skill** — your execution plan (develop, review, test, etc.)
- **Guardrails** — constraints you must follow
- **Directives** — data-driven execution rules
- **Manifest ID** — tracks your session

## Why This Exists

Without enforcement, agents skip context acquisition and start writing code immediately — missing architectural decisions, guardrails, prior manifests, and story-specific constraints. The plugin ensures every session follows the manifest workflow.

## After Acquisition

Once `acquire_context` succeeds, the guard plugin writes a session marker and all tool calls proceed normally. The marker is cleared when you call `reviewer_submit` with an outcome to close the session.
