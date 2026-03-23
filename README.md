# satellites-plugin

Claude Code plugin that enforces mandatory Satellites context acquisition before code mutations.

## Install

Add the marketplace and install the plugin:

```bash
claude plugin marketplace add github:bobmcallan/satellites-plugin
claude plugin install satellites-guard
```

## Requirements

- `SATELLITES_URL` environment variable set to your Satellites server URL (e.g. `https://satellites.example.com/mcp`)

## What It Does

Blocks `Write`, `Edit`, `MultiEdit`, and code-generating `Bash` calls until `satellites_acquire_context` has been called for the current session.

### Hook Events

| Event | Action |
|---|---|
| **UserPromptSubmit** | Validates manifest marker against server, injects reminder if missing |
| **PreToolUse (Edit/Write/MultiEdit)** | Local marker check — no HTTP call, sub-millisecond |
| **PreToolUse (Bash)** | Fast-path safe commands locally, server call for git/write operations |
| **PostToolUse (acquire_context)** | Writes session marker |
| **PostToolUse (reviewer_submit)** | Clears session marker |

### Design

- **Local-first**: Write/Edit gating uses local marker check only — no network latency
- **Server-side delivery strategy**: Git push/branch operations evaluated by `POST /api/enforce`
- **Graceful degradation**: Server unreachable does not block the developer
- **Cross-project**: Install once, works in every repo — no per-project setup
