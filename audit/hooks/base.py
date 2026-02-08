"""
Base hook class — all audit hooks inherit from this.

Each hook declares:
  - name & description
  - which files it watches (glob patterns)
  - the audit prompt
  - severity thresholds

Primary provider: Claude Code CLI (claude --print) — uses Claude Pro subscription.
Fallback: Kimi 2.5 via NVIDIA NIM API.
No Anthropic API key or credits needed.
"""
from __future__ import annotations

import json
import re
import subprocess
import requests
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

from .config import (
    PROJECT_ROOT, CLAUDE_CLI,
    KIMI_API_URL, KIMI_MODEL, DEFAULT_PROVIDER, OUTPUT_DIR,
    CRITICAL, HIGH, MEDIUM, LOW, SEVERITY_ORDER,
    MAX_CONTEXT_CHARS, EXCLUDE_PATTERNS,
    load_kimi_api_key, check_claude_cli,
)

# ─── Registry ─────────────────────────────────────────────────────────────────

_HOOK_REGISTRY: dict[str, type[BaseHook]] = {}


def register_hook(cls):
    """Class decorator to register a hook in the global registry."""
    _HOOK_REGISTRY[cls.hook_name] = cls
    return cls


def get_all_hooks() -> dict[str, type[BaseHook]]:
    return dict(_HOOK_REGISTRY)


def get_hook(name: str) -> type[BaseHook]:
    if name not in _HOOK_REGISTRY:
        available = ", ".join(sorted(_HOOK_REGISTRY.keys()))
        raise KeyError(f"Unknown hook '{name}'. Available: {available}")
    return _HOOK_REGISTRY[name]


# ─── Data Classes ─────────────────────────────────────────────────────────────

@dataclass
class Finding:
    """A single audit finding."""
    severity: str           # CRITICAL, HIGH, MEDIUM, LOW
    title: str              # Short summary
    description: str        # Detailed explanation
    file: str               # Affected file (relative path)
    line: Optional[int] = None      # Line number if applicable
    fix_suggestion: str = ""        # Suggested code fix
    category: str = ""              # e.g. "security", "logic", "performance"

    def to_dict(self) -> dict:
        return {
            "severity": self.severity,
            "title": self.title,
            "description": self.description,
            "file": self.file,
            "line": self.line,
            "fix_suggestion": self.fix_suggestion,
            "category": self.category,
        }

    @property
    def severity_rank(self) -> int:
        return SEVERITY_ORDER.get(self.severity, 99)


@dataclass
class HookResult:
    """Result from running a single hook."""
    hook_name: str
    status: str             # "success", "error", "skipped"
    findings: list[Finding] = field(default_factory=list)
    markdown_report: str = ""
    error: str = ""
    duration_seconds: float = 0.0
    files_audited: int = 0

    @property
    def critical_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == CRITICAL)

    @property
    def high_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == HIGH)

    def to_dict(self) -> dict:
        return {
            "hook_name": self.hook_name,
            "status": self.status,
            "findings": [f.to_dict() for f in self.findings],
            "error": self.error,
            "duration_seconds": self.duration_seconds,
            "files_audited": self.files_audited,
            "summary": {
                "critical": self.critical_count,
                "high": self.high_count,
                "medium": sum(1 for f in self.findings if f.severity == MEDIUM),
                "low": sum(1 for f in self.findings if f.severity == LOW),
                "total": len(self.findings),
            },
        }


# ─── Base Hook ────────────────────────────────────────────────────────────────

class BaseHook(ABC):
    """
    Abstract base for all audit hooks.

    Subclass and override:
      - hook_name: unique identifier
      - description: human-readable description
      - watch_patterns: list of file glob patterns this hook cares about
      - target_files: list of specific files to always include
      - get_prompt(): return the audit prompt
    """
    hook_name: str = "base"
    description: str = "Base audit hook"
    emoji: str = "🔍"

    # Files this hook monitors (glob patterns relative to PROJECT_ROOT)
    watch_patterns: list[str] = []

    # Specific files to always include in this audit
    target_files: list[str] = []

    def __init__(self, provider: str = DEFAULT_PROVIDER):
        self.provider = provider

    # ── Abstract ──────────────────────────────────────────────────────────

    @abstractmethod
    def get_prompt(self) -> str:
        """Return the audit system prompt for this hook."""
        ...

    # ── File Targeting ────────────────────────────────────────────────────

    def matches_file(self, filepath: str) -> bool:
        """Check if a file path matches this hook's watch patterns."""
        from fnmatch import fnmatch
        rel = filepath
        for pattern in self.watch_patterns:
            if fnmatch(rel, pattern):
                return True
        return False

    def resolve_files(self, changed_only: list[str] | None = None) -> list[Path]:
        """
        Get the list of files to audit.

        If changed_only is provided, intersect with watch_patterns.
        Otherwise, use target_files.
        """
        files = []

        if changed_only is not None:
            # Git-diff mode: only audit changed files that match our patterns
            for f in changed_only:
                if self.matches_file(f):
                    path = PROJECT_ROOT / f
                    if path.exists():
                        files.append(path)
            # Always include critical context files even in changed-only mode
            for f in self.target_files[:5]:  # First 5 are considered "core context"
                path = PROJECT_ROOT / f
                if path.exists() and path not in files:
                    files.append(path)
        else:
            # Full mode: use all target files
            for f in self.target_files:
                path = PROJECT_ROOT / f
                if path.exists():
                    files.append(path)

        return files

    def bundle_files(self, files: list[Path]) -> str:
        """Bundle file contents into a single string."""
        content = []
        total = 0

        for path in files:
            try:
                text = path.read_text(errors="ignore")
            except Exception:
                continue

            try:
                rel = path.relative_to(PROJECT_ROOT)
            except ValueError:
                rel = path

            block = f"\n\n### FILE: {rel}\n```\n{text}\n```"
            if total + len(block) > MAX_CONTEXT_CHARS:
                remaining = len(files) - len(content)
                content.append(
                    f"\n\n[TRUNCATED — {remaining} files omitted due to size limit]"
                )
                break
            content.append(block)
            total += len(block)

        return "".join(content)

    # ── LLM Calls ─────────────────────────────────────────────────────────
    # Primary: Claude Code CLI (claude -p --print) — uses Claude Pro subscription
    # Fallback: Kimi 2.5 via NVIDIA NIM API

    def call_claude_cli(self, prompt: str, context: str) -> str:
        """
        Call Claude via the Claude Code CLI (uses Claude Pro subscription).
        
        Pipes the full prompt+context via stdin to: claude -p --print --model sonnet
        No API key needed — authenticated via Claude Pro login.
        """
        if not check_claude_cli():
            raise RuntimeError(
                "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code\n"
                "Then login: claude login"
            )

        full_prompt = prompt + "\n\n" + context

        print(f"  📡 Calling Claude Code CLI (Pro subscription)...")
        print(f"  📦 Prompt size: {len(full_prompt):,} chars")

        try:
            result = subprocess.run(
                [
                    CLAUDE_CLI,
                    "-p",           # Non-interactive, print mode
                    "--model", "sonnet",  # Use latest Sonnet model
                ],
                input=full_prompt,
                capture_output=True,
                text=True,
                cwd=str(PROJECT_ROOT),
                timeout=600,  # 10 minute timeout
            )

            # Check for rate limit / quota
            combined_output = (result.stdout + result.stderr).strip()
            if "limit" in combined_output.lower() and "reset" in combined_output.lower():
                raise RuntimeError(f"Claude Pro rate limit reached: {combined_output[:200]}")

            if result.returncode != 0:
                stderr = result.stderr.strip()
                if "not logged in" in stderr.lower() or "auth" in stderr.lower():
                    raise RuntimeError(
                        f"Claude CLI auth error. Run: claude login\n{stderr[:200]}"
                    )
                if "limit" in stderr.lower():
                    raise RuntimeError(f"Claude Pro rate limit: {stderr[:200]}")
                raise RuntimeError(
                    f"Claude CLI failed (exit {result.returncode}): {stderr[:300]}"
                )

            output = result.stdout.strip()
            if not output:
                raise RuntimeError("Claude CLI returned empty output")

            print(f"  ✅ Received {len(output):,} chars from Claude Pro")
            return output

        except subprocess.TimeoutExpired:
            raise RuntimeError("Claude CLI timed out after 600s")

    def call_kimi(self, prompt: str, context: str) -> str:
        """Send request to Kimi 2.5 API (fallback when Claude Pro is rate-limited)."""
        api_key = load_kimi_api_key()

        payload = {
            "model": KIMI_MODEL,
            "messages": [{"role": "user", "content": prompt + "\n\n" + context}],
            "temperature": 0.3,
            "max_tokens": 8192,
            "stream": True,
        }
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Accept": "text/event-stream",
            "Content-Type": "application/json",
        }

        print(f"  📡 Sending to {KIMI_MODEL} (fallback)...")
        res = requests.post(
            KIMI_API_URL, headers=headers, json=payload,
            timeout=(30, 600), stream=True,
        )
        res.raise_for_status()

        chunks = []
        for line in res.iter_lines(decode_unicode=True):
            if not line or not line.startswith("data: "):
                continue
            data_str = line[len("data: "):]
            if data_str.strip() == "[DONE]":
                break
            chunk = json.loads(data_str)
            delta = chunk["choices"][0].get("delta", {})
            text = delta.get("content", "")
            if text:
                chunks.append(text)
                print(text, end="", flush=True)

        print()  # newline after streaming
        result = "".join(chunks)
        print(f"  ✅ Received {len(result):,} chars from Kimi")
        return result

    def call_llm(self, prompt: str, context: str) -> str:
        """
        Call the configured LLM provider, with automatic fallback.
        
        Claude Pro (CLI) → Kimi 2.5 (API) on rate-limit/error.
        """
        if self.provider == "claude":
            try:
                return self.call_claude_cli(prompt, context)
            except RuntimeError as e:
                error_msg = str(e)
                print(f"  ⚠️  Claude: {error_msg[:150]}")
                if "not found" in error_msg.lower():
                    raise  # Don't fallback if CLI isn't installed
                print(f"  🔄 Falling back to Kimi 2.5...")
                self.provider = "kimi"
                return self.call_kimi(prompt, context)
        else:
            return self.call_kimi(prompt, context)

    # ── Parsing ───────────────────────────────────────────────────────────

    def parse_findings(self, raw_response: str) -> list[Finding]:
        """
        Parse structured findings from the LLM response.

        The prompt instructs the LLM to output a JSON block with findings.
        We extract it and parse it. Falls back to regex extraction.
        """
        findings = []

        # Strategy 1: Look for ```json ... ``` block with findings array
        json_match = re.search(
            r'```json\s*\n(\[.*?\])\s*\n```',
            raw_response,
            re.DOTALL,
        )
        if json_match:
            try:
                items = json.loads(json_match.group(1))
                for item in items:
                    findings.append(Finding(
                        severity=item.get("severity", MEDIUM),
                        title=item.get("title", "Untitled"),
                        description=item.get("description", ""),
                        file=item.get("file", "unknown"),
                        line=item.get("line"),
                        fix_suggestion=item.get("fix_suggestion", ""),
                        category=item.get("category", ""),
                    ))
                return findings
            except (json.JSONDecodeError, KeyError):
                pass

        # Strategy 2: Regex extraction from markdown
        # Look for patterns like: **CRITICAL** | `file.py` | description
        pattern = re.compile(
            r'\*\*?(CRITICAL|HIGH|MEDIUM|LOW)\*?\*?\s*[|:—–-]\s*'
            r'[`"]?([^`"\n|]+?)[`"]?\s*[|:—–-]\s*'
            r'(.+?)(?=\n\*\*?(?:CRITICAL|HIGH|MEDIUM|LOW)|\n#{1,3}\s|\Z)',
            re.DOTALL | re.IGNORECASE,
        )
        for match in pattern.finditer(raw_response):
            severity = match.group(1).upper()
            file_ref = match.group(2).strip()
            desc = match.group(3).strip()
            findings.append(Finding(
                severity=severity,
                title=desc[:80],
                description=desc,
                file=file_ref,
                category="general",
            ))

        return findings

    # ── Main Run ──────────────────────────────────────────────────────────

    def run(self, changed_only: list[str] | None = None) -> HookResult:
        """
        Execute this audit hook.

        Args:
            changed_only: If provided, list of changed file paths (relative to PROJECT_ROOT).
                         Only files matching this hook's watch_patterns will be audited.

        Returns:
            HookResult with findings and report.
        """
        import time
        start = time.time()

        result = HookResult(hook_name=self.hook_name, status="success")

        try:
            # 1. Resolve files
            files = self.resolve_files(changed_only)
            if not files:
                result.status = "skipped"
                result.error = "No matching files to audit"
                return result

            result.files_audited = len(files)
            print(f"\n{self.emoji} {self.hook_name}: Auditing {len(files)} files...")

            # 2. Bundle files
            context = self.bundle_files(files)
            print(f"  📦 Context: {len(context):,} chars")

            # 3. Get prompt
            prompt = self.get_prompt()

            # 4. Call LLM
            raw_response = self.call_llm(prompt, context)

            # 5. Parse findings
            result.findings = self.parse_findings(raw_response)
            result.markdown_report = raw_response

            # Sort by severity
            result.findings.sort(key=lambda f: f.severity_rank)

        except Exception as e:
            result.status = "error"
            result.error = str(e)
            print(f"  ❌ Error: {e}")

        result.duration_seconds = round(time.time() - start, 2)
        return result


# ─── Utility: Get Changed Files ──────────────────────────────────────────────

def get_git_changed_files(staged_only: bool = False) -> list[str]:
    """Get list of changed files from git (relative to PROJECT_ROOT)."""
    try:
        if staged_only:
            cmd = ["git", "diff", "--cached", "--name-only"]
        else:
            cmd = ["git", "diff", "--name-only", "HEAD"]
        result = subprocess.run(
            cmd, capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if result.returncode != 0:
            # Fallback: unstaged changes
            result = subprocess.run(
                ["git", "diff", "--name-only"],
                capture_output=True, text=True, cwd=str(PROJECT_ROOT),
            )
        files = [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]

        # Also include untracked files
        untracked = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard"],
            capture_output=True, text=True, cwd=str(PROJECT_ROOT),
        )
        if untracked.returncode == 0:
            files += [f.strip() for f in untracked.stdout.strip().split("\n") if f.strip()]

        # Deduplicate
        return list(dict.fromkeys(files))
    except Exception:
        return []
