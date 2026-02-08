"""
Configuration for the Claude-powered audit hook system.

Uses Claude Code CLI (claude --print) which works with Claude Pro subscription.
NO Anthropic API needed — no billing, no credits, no API keys for Claude.
"""
import os
import shutil
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

# ─── Provider Configuration ───────────────────────────────────────────────────

# Primary: Claude Code CLI (uses Claude Pro subscription — FREE)
CLAUDE_CLI = shutil.which("claude") or os.path.expanduser("~/.local/bin/claude")

# Fallback: Kimi 2.5 (NVIDIA NIM API — only if Claude CLI unavailable)
KIMI_API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
KIMI_MODEL = "moonshotai/kimi-k2.5"

# Provider selection: "claude" (CLI) or "kimi" (API)
DEFAULT_PROVIDER = "claude"

# ─── Audit Settings ──────────────────────────────────────────────────────────

# Severity levels
CRITICAL = "CRITICAL"  # Must fix before production — security holes, data loss
HIGH = "HIGH"          # Should fix before launch — logic bugs, race conditions
MEDIUM = "MEDIUM"      # Should fix soon — anti-patterns, maintainability
LOW = "LOW"            # Nice to fix — style, minor optimizations

SEVERITY_ORDER = {CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3}

# Output
OUTPUT_DIR = PROJECT_ROOT / "audit" / "output" / "hooks"

# ─── File Targeting ──────────────────────────────────────────────────────────

# Max characters per hook context
MAX_CONTEXT_CHARS = 200_000

# Files that should never be audited
EXCLUDE_PATTERNS = {
    ".git", "node_modules", "build", ".dart_tool", "__pycache__",
    "venv", ".venv", "emulator-data", "test-results", "playwright-report",
    "audit/output", ".firebase", ".pub-cache",
}


def load_kimi_api_key() -> str:
    """Load NVIDIA NIM API key (only needed for Kimi fallback)."""
    key_name = "NVIDIA_NIM_API_KEY"

    key = os.getenv(key_name)
    if key:
        return key

    env_path = PROJECT_ROOT / "functions" / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            if k.strip() == key_name:
                return v.strip().strip('"').strip("'")

    raise RuntimeError(
        f"{key_name} not found. Set it as env var or add to functions/.env"
    )


def check_claude_cli() -> bool:
    """Check if Claude Code CLI is available."""
    return CLAUDE_CLI is not None and Path(CLAUDE_CLI).exists()
