# /latest-features — Claude Code March 2026 Features

Quick reference for the latest Claude Code features (v2.1.76-2.1.81).

## New Features to Use

### --channels (v2.1.81) — Control from Phone
```bash
claude --channels
```
Forward permission prompts and messages to Telegram/Discord. Requires channel MCP server.

### --bare (v2.1.81) — Scripted Calls
```bash
claude --bare -p "task description"
```
Skips hooks, LSP, plugins. Pure API call for scripted automation.

### /effort (v2.1.76) — Model Effort Level
Set how hard Claude thinks. Also available as `effort` frontmatter in skills.

### /remote-control (v2.1.79) — VS Code → Browser Bridge
Continue your VS Code session from claude.ai on phone/browser.

### StopFailure Hook (v2.1.78)
Fires when turn ends due to API error (rate limit, auth). Use for error recovery.

### PostCompact Hook (v2.1.76)
Fires after compaction. Use to restore critical state.

### effort Frontmatter (v2.1.80)
Add `effort: high` to skill/command frontmatter to override model effort.

### 128K Max Output (v2.1.78)
Opus 4.6 now supports up to 128K output tokens (64K default).

### SendMessage Auto-Resume (v2.1.77)
`SendMessage({to: agentId})` auto-resumes stopped agents.

### worktree.sparsePaths (v2.1.76)
For large monorepos: `worktree.sparsePaths: ["lib/", "test/"]` checks out only needed dirs.

### rate_limits in Statusline (v2.1.80)
See your 5-hour and 7-day rate limit usage in the status bar.

## Performance Improvements
- 80MB startup savings on 250K-file repos (v2.1.80)
- 18MB startup reduction across all scenarios (v2.1.79)
- 45% faster --resume on large sessions (v2.1.77)
- 60ms faster macOS startup via parallel keychain reads (v2.1.77)
