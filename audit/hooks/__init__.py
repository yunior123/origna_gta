"""
Audit Hooks — Claude Pro powered, composable code audit system for OrignaGta.

Uses Claude Code CLI (claude -p) with your Claude Pro subscription.
NO Anthropic API key or credits needed.
Falls back to Kimi 2.5 (NVIDIA NIM) when Claude is rate-limited.

Improvements over the Kimi-only audit system:
  • Hook registry: each domain is a self-contained, composable hook
  • Git-aware: can audit only changed files (fast mode for pre-commit)
  • Structured JSON findings with severity levels (CRITICAL/HIGH/MEDIUM/LOW)
  • Auto-fix suggestions with optional apply
  • Pre-commit integration
  • Parallel hook execution
  • Claude Pro via CLI for better reasoning + automatic Kimi fallback

Usage:
  python audit/run_hooks.py                       # Run all hooks on full codebase
  python audit/run_hooks.py --changed             # Run only on git-changed files
  python audit/run_hooks.py --hook payment        # Run specific hook
  python audit/run_hooks.py --hook payment,auth   # Run multiple hooks
  python audit/run_hooks.py --pre-commit          # Pre-commit mode (fast, changed files only)
  python audit/run_hooks.py --provider kimi       # Force Kimi instead of Claude
  python audit/run_hooks.py --list                # List all available hooks
"""
