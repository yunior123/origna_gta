#!/usr/bin/env python3
"""
Telegram Multi-AI Agent Bot
All models have full access to: filesystem, CLI, terminal, search.

Supported models:
  Claude  - Claude Code CLI (native agent, full tooling)
  Copilot - GPT-4o via GitHub Models API (function calling)
  Kimi    - Kimi 2.5 via NVIDIA NIM API (function calling)
  Gemini  - Gemini Flash via Google AI API (function calling)

Commands:
  /start /claude /copilot /kimi /gemini /model /models /clear /test /help
"""

import os
import subprocess
import asyncio
import logging
import json
import glob
from pathlib import Path

import requests
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    filters,
    ContextTypes,
)

logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(message)s", level=logging.INFO
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Load .env
# ---------------------------------------------------------------------------
ENV_PATH = Path(__file__).parent / "functions" / ".env"
if ENV_PATH.exists():
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and value:
                os.environ.setdefault(key, value)

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
PROJECT_DIR = Path(__file__).parent.resolve()
CLAUDE_CLI = "/Users/yuniorrodriguezosorio/.local/bin/claude"

NIM_API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
NIM_API_KEY = os.getenv("NVIDIA_NIM_API_KEY")
KIMI_MODEL = "moonshotai/kimi-k2.5"

GITHUB_MODELS_URL = "https://models.inference.ai.azure.com/chat/completions"
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
COPILOT_MODEL = "gpt-4o"

GEMINI_API_KEY = os.getenv("GOOGLE_GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.0-flash"
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models"

MAX_AGENT_ITERATIONS = 8
MAX_OUTPUT_CHARS = 3000

SYSTEM_PROMPT = (
    "You are a senior staff engineer with FULL ACCESS to the local filesystem, "
    "CLI, and terminal on a macOS machine.\n\n"
    "Project: OrignaGta - Canada-only e-commerce marketplace\n"
    "Stack: Flutter + Firebase + Stripe Connect + Python Cloud Functions\n"
    f"Working directory: {PROJECT_DIR}\n\n"
    "Key facts:\n"
    "- MVVM architecture, Flutter frontend, Python Firebase Functions backend\n"
    "- Stripe Connect Express for payments (direct charges, 2.5% platform fee)\n"
    "- Firestore database, Algolia search, R2 Cloudflare for images\n"
    "- Schema source of truth: docs/database_schema.json\n"
    "- All money in integer CENTS\n\n"
    "You have these tools available:\n"
    "- read_file: Read file contents (provide path relative to project or absolute)\n"
    "- create_file: Create a NEW file (fails if file already exists)\n"
    "- edit_file: Replace specific text in an existing file (find-and-replace)\n"
    "- append_file: Append content to the end of an existing file\n"
    "- run_command: Execute a shell command (bash) — some dangerous commands are blocked\n"
    "- list_directory: List files/folders in a directory\n"
    "- search_text: Search for text/regex across files (grep)\n"
    "- web_search: Search the web using DuckDuckGo (returns top results)\n"
    "- fetch_url: Fetch and extract text content from any URL\n\n"
    "IMPORTANT SAFETY RULES:\n"
    "- You CANNOT overwrite existing files. Use edit_file to modify them.\n"
    "- To edit a file: first read_file, then use edit_file with the exact old_text you want to replace.\n"
    "- To add content to a file: use append_file.\n"
    "- To create a new file: use create_file (only works for files that don't exist yet).\n"
    "- NEVER use run_command with redirects (>) to overwrite files. Use the file tools instead.\n"
    "- READ-ONLY FILES (NEVER modify): CLAUDE.md, telegram_bot.py, .env, serviceAccountKey.json\n"
    "- If a user asks you to modify a read-only file, REFUSE and explain it's protected.\n\n"
    "USE YOUR TOOLS. When asked to read, edit, run, search, or look something up online - actually do it. "
    "Do not say you cannot access files or the web. You CAN and SHOULD use the tools.\n"
    "Be concise, direct, actionable. No filler."
)

MODELS = {
    "claude": {
        "icon": "\U0001f7e3",
        "name": "Claude Code",
        "desc": "Full agent (native CLI tooling)",
    },
    "copilot": {
        "icon": "\U0001f7e2",
        "name": "Copilot (GPT-4o)",
        "desc": "Agent with file/CLI access (GitHub)",
    },
    "kimi": {
        "icon": "\U0001f535",
        "name": "Kimi 2.5",
        "desc": "Agent with file/CLI access (NIM)",
    },
    "gemini": {
        "icon": "\U0001f7e1",
        "name": "Gemini Flash",
        "desc": "Agent with file/CLI access (Google)",
    },
}

ALLOWED_USER_ID = None
if not TELEGRAM_BOT_TOKEN:
    raise ValueError("TELEGRAM_BOT_TOKEN not set in functions/.env")

conversations: dict[int, list] = {}
user_models: dict[int, str] = {}


# =========================================================================
# TOOL DEFINITIONS (OpenAI format - used by Copilot & Kimi)
# =========================================================================

OPENAI_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": (
                "Read the contents of a file. Returns the file text. "
                "Use relative paths from project root or absolute paths."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "File path (relative to project or absolute)",
                    },
                    "start_line": {
                        "type": "integer",
                        "description": "Optional start line (1-based). Omit to read entire file.",
                    },
                    "end_line": {
                        "type": "integer",
                        "description": "Optional end line (1-based, inclusive).",
                    },
                },
                "required": ["path"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "create_file",
            "description": (
                "Create a NEW file. FAILS if the file already exists. "
                "Use edit_file to modify existing files, append_file to add content."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "File path (relative or absolute)",
                    },
                    "content": {
                        "type": "string",
                        "description": "The full content for the new file",
                    },
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "edit_file",
            "description": (
                "Replace specific text in an existing file. Like find-and-replace. "
                "You MUST read the file first to get the exact old_text. "
                "Replaces only the FIRST occurrence."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to existing file",
                    },
                    "old_text": {
                        "type": "string",
                        "description": "Exact text to find (must match file content exactly)",
                    },
                    "new_text": {
                        "type": "string",
                        "description": "Text to replace old_text with",
                    },
                },
                "required": ["path", "old_text", "new_text"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "append_file",
            "description": "Append content to the END of an existing file. File must already exist.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to existing file",
                    },
                    "content": {
                        "type": "string",
                        "description": "Content to append at the end",
                    },
                },
                "required": ["path", "content"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "run_command",
            "description": (
                "Execute a shell command (bash) and return stdout+stderr. "
                "Runs in the project directory. Use for: git, flutter, python, "
                "firebase, npm, pip, curl, etc."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "description": "The shell command to execute",
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Timeout in seconds (default 30, max 120)",
                    },
                },
                "required": ["command"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "list_directory",
            "description": "List files and subdirectories in a directory.",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Directory path (default: project root)",
                    },
                    "recursive": {
                        "type": "boolean",
                        "description": "If true, list recursively (max 2 levels deep)",
                    },
                },
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "search_text",
            "description": (
                "Search for text or regex pattern across files. "
                "Returns matching lines with file paths and line numbers."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "pattern": {
                        "type": "string",
                        "description": "Text or regex pattern to search for",
                    },
                    "path": {
                        "type": "string",
                        "description": "Directory or file to search in (default: project root)",
                    },
                    "file_pattern": {
                        "type": "string",
                        "description": "Glob pattern for files to include (e.g. '*.py', '*.dart')",
                    },
                },
                "required": ["pattern"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "web_search",
            "description": (
                "Search the web using DuckDuckGo. Returns top results with titles, "
                "URLs, and snippets. Use for: documentation lookups, API references, "
                "error messages, package info, tutorials, news."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The search query",
                    },
                    "max_results": {
                        "type": "integer",
                        "description": "Max results to return (default 5, max 10)",
                    },
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "fetch_url",
            "description": (
                "Fetch the text content of a web page. Strips HTML and returns "
                "readable text. Use to read documentation, API references, articles."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "The URL to fetch",
                    },
                },
                "required": ["url"],
            },
        },
    },
]

# Gemini tool format
GEMINI_TOOLS = [
    {
        "functionDeclarations": [
            {
                "name": "read_file",
                "description": (
                    "Read the contents of a file. Returns the file text. "
                    "Use relative paths from project root or absolute paths."
                ),
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "path": {"type": "STRING", "description": "File path"},
                        "start_line": {"type": "INTEGER", "description": "Optional start line (1-based)"},
                        "end_line": {"type": "INTEGER", "description": "Optional end line (1-based)"},
                    },
                    "required": ["path"],
                },
            },
            {
                "name": "create_file",
                "description": "Create a NEW file. FAILS if file already exists. Use edit_file to modify existing files.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "path": {"type": "STRING", "description": "File path"},
                        "content": {"type": "STRING", "description": "Content for the new file"},
                    },
                    "required": ["path", "content"],
                },
            },
            {
                "name": "edit_file",
                "description": "Replace specific text in an existing file (find-and-replace). Read file first to get exact old_text.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "path": {"type": "STRING", "description": "Path to existing file"},
                        "old_text": {"type": "STRING", "description": "Exact text to find"},
                        "new_text": {"type": "STRING", "description": "Replacement text"},
                    },
                    "required": ["path", "old_text", "new_text"],
                },
            },
            {
                "name": "append_file",
                "description": "Append content to end of an existing file.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "path": {"type": "STRING", "description": "Path to existing file"},
                        "content": {"type": "STRING", "description": "Content to append"},
                    },
                    "required": ["path", "content"],
                },
            },
            {
                "name": "run_command",
                "description": "Execute a shell command (bash) and return stdout+stderr.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "command": {"type": "STRING", "description": "Shell command"},
                        "timeout": {"type": "INTEGER", "description": "Timeout in seconds (default 30)"},
                    },
                    "required": ["command"],
                },
            },
            {
                "name": "list_directory",
                "description": "List files and subdirectories in a directory.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "path": {"type": "STRING", "description": "Directory path"},
                        "recursive": {"type": "BOOLEAN", "description": "List recursively"},
                    },
                    "required": [],
                },
            },
            {
                "name": "search_text",
                "description": "Search for text/regex across files. Returns matching lines.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "pattern": {"type": "STRING", "description": "Search pattern"},
                        "path": {"type": "STRING", "description": "Dir or file to search"},
                        "file_pattern": {"type": "STRING", "description": "Glob like *.py"},
                    },
                    "required": ["pattern"],
                },
            },
            {
                "name": "web_search",
                "description": "Search the web using DuckDuckGo. Returns top results with titles, URLs, snippets.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "query": {"type": "STRING", "description": "Search query"},
                        "max_results": {"type": "INTEGER", "description": "Max results (default 5)"},
                    },
                    "required": ["query"],
                },
            },
            {
                "name": "fetch_url",
                "description": "Fetch text content from a web page URL. Strips HTML.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {
                        "url": {"type": "STRING", "description": "URL to fetch"},
                    },
                    "required": ["url"],
                },
            },
        ]
    }
]


# =========================================================================
# TOOL EXECUTORS
# =========================================================================


def _resolve_path(path: str) -> Path:
    """Resolve a path relative to PROJECT_DIR or absolute."""
    p = Path(path)
    if not p.is_absolute():
        p = PROJECT_DIR / p
    return p.resolve()


def tool_read_file(path: str, start_line: int = None, end_line: int = None) -> str:
    """Read file contents, optionally a line range."""
    try:
        fp = _resolve_path(path)
        if not fp.exists():
            return f"ERROR: File not found: {fp}"
        if not fp.is_file():
            return f"ERROR: Not a file: {fp}"
        if fp.stat().st_size > 500_000:
            return f"ERROR: File too large ({fp.stat().st_size} bytes). Use start_line/end_line."
        text = fp.read_text(errors="replace")
        if start_line is not None or end_line is not None:
            lines = text.splitlines(keepends=True)
            s = max(0, (start_line or 1) - 1)
            e = end_line or len(lines)
            text = "".join(lines[s:e])
        if len(text) > MAX_OUTPUT_CHARS:
            text = text[:MAX_OUTPUT_CHARS] + f"\n... (truncated, {len(text)} total chars)"
        return text
    except Exception as e:
        return f"ERROR: {e}"


# Protected files that cannot be overwritten or deleted
PROTECTED_FILES = {
    "CLAUDE.md", ".env", "serviceAccountKey.json",
    "firebase.json", "firestore.rules", "storage.rules",
    "firestore.indexes.json", "main.py", "telegram_bot.py",
}

# Files that are COMPLETELY READ-ONLY — no edits, no appends, no deletes
READONLY_FILES = {
    "CLAUDE.md", "telegram_bot.py", ".env", "serviceAccountKey.json",
}

# Dangerous command patterns blocked in run_command
DANGEROUS_PATTERNS = [
    "rm -rf /", "rm -rf ~", "rm -rf .", "rm -rf *",
    "rm -rf /*", "rmdir /", "mkfs", "dd if=",
    ":(){:|:&};:",  # fork bomb
    "> /dev/sd", "chmod -R 777 /",
    "curl|sh", "curl|bash", "wget|sh", "wget|bash",
    "curl | sh", "curl | bash", "wget | sh", "wget | bash",
]


def _is_protected(fp: Path) -> bool:
    """Check if a file is in the protected list."""
    return fp.name in PROTECTED_FILES


def _is_readonly(fp: Path) -> bool:
    """Check if a file is completely read-only."""
    return fp.name in READONLY_FILES


def tool_create_file(path: str, content: str) -> str:
    """Create a NEW file. Fails if the file already exists."""
    try:
        fp = _resolve_path(path)
        if fp.exists():
            return (
                f"ERROR: File already exists: {fp}\n"
                f"Use edit_file to modify existing files, or append_file to add content."
            )
        fp.parent.mkdir(parents=True, exist_ok=True)
        fp.write_text(content)
        return f"OK: Created {fp} ({len(content)} chars)"
    except Exception as e:
        return f"ERROR: {e}"


def tool_edit_file(path: str, old_text: str, new_text: str) -> str:
    """Replace specific text in an existing file (find-and-replace, first occurrence only)."""
    try:
        fp = _resolve_path(path)
        if not fp.exists():
            return f"ERROR: File not found: {fp}\nUse create_file for new files."
        if not fp.is_file():
            return f"ERROR: Not a file: {fp}"
        if _is_readonly(fp):
            return f"BLOCKED: {fp.name} is READ-ONLY. You cannot modify this file."
        content = fp.read_text(errors="replace")
        if old_text not in content:
            # Show a preview to help the model
            preview = content[:500]
            return (
                f"ERROR: old_text not found in {fp.name}. "
                f"Read the file first to get exact text.\n"
                f"File preview:\n{preview}"
            )
        count = content.count(old_text)
        new_content = content.replace(old_text, new_text, 1)
        # Safety: warn on large changes
        size_diff = abs(len(new_content) - len(content))
        fp.write_text(new_content)
        msg = f"OK: Edited {fp.name} (replaced {len(old_text)} -> {len(new_text)} chars)"
        if count > 1:
            msg += f"\nNOTE: Found {count} occurrences, replaced only the FIRST one."
        return msg
    except Exception as e:
        return f"ERROR: {e}"


def tool_append_file(path: str, content: str) -> str:
    """Append content to the end of an existing file."""
    try:
        fp = _resolve_path(path)
        if not fp.exists():
            return f"ERROR: File not found: {fp}\nUse create_file for new files."
        if not fp.is_file():
            return f"ERROR: Not a file: {fp}"
        if _is_readonly(fp):
            return f"BLOCKED: {fp.name} is READ-ONLY. You cannot modify this file."
        with open(fp, "a") as f:
            f.write(content)
        return f"OK: Appended {len(content)} chars to {fp.name}"
    except Exception as e:
        return f"ERROR: {e}"


def tool_run_command(command: str, timeout: int = 30) -> str:
    """Execute a shell command with safety guards."""
    # Check for dangerous patterns
    cmd_lower = command.lower().strip()
    for pattern in DANGEROUS_PATTERNS:
        if pattern.lower() in cmd_lower:
            return f"BLOCKED: Dangerous command pattern detected: '{pattern}'. This command is not allowed."
    # Block redirects that overwrite protected files
    for pf in PROTECTED_FILES:
        if f"> {pf}" in command or f">{pf}" in command:
            return f"BLOCKED: Cannot redirect output to protected file '{pf}'. Use edit_file or append_file instead."
    # Block any command that tries to write/modify/delete readonly files
    for rf in READONLY_FILES:
        rf_lower = rf.lower()
        # Check various write patterns targeting readonly files
        write_patterns = [
            f"sed -i", f"sed -e",  # sed in-place
            f"tee {rf}", f"tee ./{rf}",  # tee
            f"mv ", f"rm {rf}", f"rm ./{rf}",  # move/remove
            f"chmod ",  # permission change
            f"> {rf}", f">{rf}",  # redirect
            f">> {rf}", f">>{rf}",  # append redirect
            f"cp ",  # copy over
            f"truncate",  # truncate
        ]
        if rf_lower in cmd_lower:
            for wp in write_patterns:
                if wp.lower() in cmd_lower:
                    return f"BLOCKED: Cannot modify read-only file '{rf}' via command. This file is protected."
    timeout = min(max(timeout, 5), 120)
    logger.info("TOOL run_command: %s", command[:200])
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=PROJECT_DIR,
        )
        output = ""
        if result.stdout:
            output += result.stdout
        if result.stderr:
            output += ("\n--- stderr ---\n" if output else "") + result.stderr
        if not output:
            output = "(no output)"
        output = f"[exit code: {result.returncode}]\n{output}"
        if len(output) > MAX_OUTPUT_CHARS:
            output = output[:MAX_OUTPUT_CHARS] + f"\n... (truncated)"
        return output
    except subprocess.TimeoutExpired:
        return f"ERROR: Command timed out after {timeout}s"
    except Exception as e:
        return f"ERROR: {e}"


def tool_list_directory(path: str = None, recursive: bool = False) -> str:
    """List directory contents."""
    try:
        dp = _resolve_path(path) if path else PROJECT_DIR
        if not dp.exists():
            return f"ERROR: Directory not found: {dp}"
        if not dp.is_dir():
            return f"ERROR: Not a directory: {dp}"
        entries = []
        if recursive:
            for root, dirs, files in os.walk(dp):
                depth = str(root).replace(str(dp), "").count(os.sep)
                if depth > 2:
                    dirs.clear()
                    continue
                rel = Path(root).relative_to(dp)
                for f in sorted(files)[:50]:
                    entries.append(str(rel / f))
                for d in sorted(dirs)[:30]:
                    entries.append(str(rel / d) + "/")
                if len(entries) > 200:
                    entries.append("... (truncated)")
                    break
        else:
            for item in sorted(dp.iterdir()):
                suffix = "/" if item.is_dir() else ""
                entries.append(item.name + suffix)
        return "\n".join(entries) if entries else "(empty directory)"
    except Exception as e:
        return f"ERROR: {e}"


def tool_search_text(pattern: str, path: str = None, file_pattern: str = None) -> str:
    """Search for text pattern using grep."""
    try:
        search_path = _resolve_path(path) if path else PROJECT_DIR
        cmd_parts = ["grep", "-rn", "--include=" + (file_pattern or "*"), "-l" if False else ""]
        cmd = f'grep -rn --color=never'
        if file_pattern:
            cmd += f' --include="{file_pattern}"'
        cmd += f' "{pattern}" "{search_path}" 2>/dev/null | head -40'
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=15, cwd=PROJECT_DIR
        )
        output = result.stdout.strip()
        if not output:
            return f"No matches found for '{pattern}'"
        if len(output) > MAX_OUTPUT_CHARS:
            output = output[:MAX_OUTPUT_CHARS] + "\n... (truncated)"
        return output
    except Exception as e:
        return f"ERROR: {e}"


def tool_web_search(query: str, max_results: int = 5) -> str:
    """Search the web using DuckDuckGo HTML."""
    max_results = min(max(max_results, 1), 10)
    logger.info("TOOL web_search: %s", query[:100])
    try:
        # Use DuckDuckGo HTML lite search
        res = requests.get(
            "https://html.duckduckgo.com/html/",
            params={"q": query},
            headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"},
            timeout=15,
        )
        res.raise_for_status()
        html = res.text
        # Parse results from HTML (simple extraction)
        import re
        results = []
        # Find result blocks
        snippets = re.findall(
            r'<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>(.+?)</a>.*?'
            r'<a[^>]*class="result__snippet"[^>]*>(.+?)</a>',
            html, re.DOTALL
        )
        if not snippets:
            # Fallback: try simpler pattern
            snippets = re.findall(
                r'<a[^>]*rel="nofollow"[^>]*href="([^"]+)"[^>]*>(.+?)</a>',
                html, re.DOTALL
            )
            for url, title in snippets[:max_results]:
                clean_title = re.sub(r'<[^>]+>', '', title).strip()
                if clean_title and 'duckduckgo' not in url.lower():
                    results.append(f"- {clean_title}\n  {url}")
        else:
            for url, title, snippet in snippets[:max_results]:
                clean_title = re.sub(r'<[^>]+>', '', title).strip()
                clean_snippet = re.sub(r'<[^>]+>', '', snippet).strip()
                if clean_title:
                    results.append(f"- {clean_title}\n  {url}\n  {clean_snippet}")
        if not results:
            # Ultimate fallback: use DuckDuckGo API
            api_res = requests.get(
                "https://api.duckduckgo.com/",
                params={"q": query, "format": "json", "no_html": "1"},
                timeout=10,
            )
            data = api_res.json()
            abstract = data.get("AbstractText", "")
            if abstract:
                return f"DuckDuckGo answer: {abstract}\nSource: {data.get('AbstractURL', '')}"
            related = data.get("RelatedTopics", [])[:max_results]
            for topic in related:
                if isinstance(topic, dict) and topic.get("Text"):
                    results.append(f"- {topic['Text']}\n  {topic.get('FirstURL', '')}")
        if not results:
            return f"No results found for '{query}'. Try a different search query."
        return f"Search results for '{query}':\n\n" + "\n\n".join(results)
    except Exception as e:
        logger.error("web_search error: %s", e)
        return f"ERROR: Web search failed: {e}"


def tool_fetch_url(url: str) -> str:
    """Fetch and extract text content from a URL."""
    logger.info("TOOL fetch_url: %s", url[:200])
    try:
        res = requests.get(
            url,
            headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"},
            timeout=20,
            allow_redirects=True,
        )
        res.raise_for_status()
        content_type = res.headers.get("content-type", "")
        if "json" in content_type:
            # Return JSON as-is (pretty printed)
            try:
                text = json.dumps(res.json(), indent=2)
            except Exception:
                text = res.text
        elif "html" in content_type or "<html" in res.text[:500].lower():
            # Strip HTML tags for readable text
            import re
            text = res.text
            # Remove script/style blocks
            text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.DOTALL)
            text = re.sub(r'<style[^>]*>.*?</style>', '', text, flags=re.DOTALL)
            # Remove tags
            text = re.sub(r'<[^>]+>', ' ', text)
            # Clean whitespace
            text = re.sub(r'\s+', ' ', text).strip()
        else:
            text = res.text
        if len(text) > MAX_OUTPUT_CHARS:
            text = text[:MAX_OUTPUT_CHARS] + "\n... (truncated)"
        return text if text.strip() else "(empty page)"
    except requests.exceptions.Timeout:
        return "ERROR: URL fetch timed out (20s)"
    except requests.exceptions.HTTPError as e:
        return f"ERROR: HTTP {e.response.status_code} fetching {url}"
    except Exception as e:
        logger.error("fetch_url error: %s", e)
        return f"ERROR: {e}"


TOOL_DISPATCH = {
    "read_file": tool_read_file,
    "create_file": tool_create_file,
    "edit_file": tool_edit_file,
    "append_file": tool_append_file,
    "run_command": tool_run_command,
    "list_directory": tool_list_directory,
    "search_text": tool_search_text,
    "web_search": tool_web_search,
    "fetch_url": tool_fetch_url,
}


def execute_tool(name: str, arguments: dict) -> str:
    """Execute a tool by name with given arguments."""
    fn = TOOL_DISPATCH.get(name)
    if not fn:
        return f"ERROR: Unknown tool '{name}'"
    logger.info("EXEC TOOL: %s(%s)", name, str(arguments)[:200])
    try:
        result = fn(**arguments)
        logger.info("TOOL RESULT: %d chars", len(result))
        return result
    except TypeError as e:
        return f"ERROR: Bad arguments for {name}: {e}"
    except Exception as e:
        return f"ERROR: {e}"


# =========================================================================
# AGENT LOOPS (one per API provider)
# =========================================================================


def agent_copilot(messages: list) -> str:
    """GPT-4o agent loop with function calling via GitHub Models."""
    if not GITHUB_TOKEN:
        return "\u274c GITHUB_TOKEN not set"

    for iteration in range(MAX_AGENT_ITERATIONS):
        logger.info("Copilot iteration %d, msgs=%d", iteration, len(messages))
        try:
            payload = {
                "model": COPILOT_MODEL,
                "messages": messages,
                "tools": OPENAI_TOOLS,
                "tool_choice": "auto",
                "temperature": 0.2,
                "max_tokens": 4096,
            }
            res = requests.post(
                GITHUB_MODELS_URL,
                headers={
                    "Authorization": f"Bearer {GITHUB_TOKEN}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=(10, 60),
            )
            res.raise_for_status()
            choice = res.json()["choices"][0]
            msg = choice["message"]
            finish = choice.get("finish_reason", "")

            # If model wants to call tools
            if msg.get("tool_calls"):
                messages.append(msg)
                for tc in msg["tool_calls"]:
                    fn_name = tc["function"]["name"]
                    try:
                        fn_args = json.loads(tc["function"]["arguments"])
                    except json.JSONDecodeError:
                        fn_args = {}
                    result = execute_tool(fn_name, fn_args)
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": result,
                    })
                continue

            # Final text response
            content = (msg.get("content") or "").strip()
            return content if content else "(empty response)"

        except requests.exceptions.Timeout:
            return "\u23f1 Copilot timed out"
        except requests.exceptions.HTTPError as e:
            body = e.response.text[:500] if e.response else ""
            logger.error("Copilot HTTP error: %s", body)
            return f"\u274c Copilot error {e.response.status_code}: {body}"
        except Exception as e:
            logger.error("Copilot error: %s", e)
            return f"\u274c Copilot error: {e}"

    return "(max iterations reached - Copilot used all tool rounds)"


def agent_kimi(messages: list) -> str:
    """Kimi 2.5 agent loop with function calling via NIM."""
    if not NIM_API_KEY:
        return "\u274c NVIDIA_NIM_API_KEY not set"

    for iteration in range(MAX_AGENT_ITERATIONS):
        logger.info("Kimi iteration %d, msgs=%d", iteration, len(messages))
        try:
            payload = {
                "model": KIMI_MODEL,
                "messages": messages,
                "tools": OPENAI_TOOLS,
                "tool_choice": "auto",
                "temperature": 0.2,
                "max_tokens": 8192,
                "stream": False,
            }
            res = requests.post(
                NIM_API_URL,
                headers={
                    "Authorization": f"Bearer {NIM_API_KEY}",
                    "Content-Type": "application/json",
                },
                json=payload,
                timeout=(15, 90),
            )
            res.raise_for_status()
            choice = res.json()["choices"][0]
            msg = choice["message"]

            # If model wants to call tools
            if msg.get("tool_calls"):
                # Build a clean assistant message for the conversation
                assistant_msg = {"role": "assistant", "content": msg.get("content") or None, "tool_calls": msg["tool_calls"]}
                messages.append(assistant_msg)
                for tc in msg["tool_calls"]:
                    fn_name = tc["function"]["name"]
                    try:
                        fn_args = json.loads(tc["function"]["arguments"])
                    except json.JSONDecodeError:
                        fn_args = {}
                    result = execute_tool(fn_name, fn_args)
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc["id"],
                        "content": result,
                    })
                continue

            # Final text response
            content = (msg.get("content") or "").strip()
            reasoning = (msg.get("reasoning_content") or "").strip()
            if content:
                return content
            elif reasoning:
                return f"\U0001f9e0 Kimi reasoning:\n\n{reasoning[:3500]}"
            return "(empty response from Kimi)"

        except requests.exceptions.Timeout:
            return "\u23f1 Kimi timed out (NIM free tier may be slow)"
        except requests.exceptions.HTTPError as e:
            body = e.response.text[:500] if e.response else ""
            logger.error("Kimi HTTP error: %s", body)
            return f"\u274c Kimi error {e.response.status_code}: {body}"
        except Exception as e:
            logger.error("Kimi error: %s", e)
            return f"\u274c Kimi error: {e}"

    return "(max iterations reached - Kimi used all tool rounds)"


def agent_gemini(messages: list) -> str:
    """Gemini agent loop with function calling via Google AI API."""
    if not GEMINI_API_KEY:
        return (
            "\u274c GOOGLE_GEMINI_API_KEY not set\n\n"
            "Get key: https://aistudio.google.com/apikey"
        )

    # Convert messages to Gemini format
    system_text = ""
    gemini_contents = []
    for msg in messages:
        if msg["role"] == "system":
            system_text = msg["content"]
            continue
        if msg["role"] == "user":
            gemini_contents.append({"role": "user", "parts": [{"text": msg["content"]}]})
        elif msg["role"] == "assistant":
            gemini_contents.append({"role": "model", "parts": [{"text": msg.get("content") or ""}]})

    url = f"{GEMINI_API_URL}/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"

    for iteration in range(MAX_AGENT_ITERATIONS):
        logger.info("Gemini iteration %d, parts=%d", iteration, len(gemini_contents))
        try:
            payload = {
                "contents": gemini_contents,
                "tools": GEMINI_TOOLS,
                "generationConfig": {"temperature": 0.2, "maxOutputTokens": 4096},
            }
            if system_text:
                payload["systemInstruction"] = {"parts": [{"text": system_text}]}

            res = requests.post(url, json=payload, timeout=(10, 60))
            res.raise_for_status()
            data = res.json()

            candidates = data.get("candidates", [])
            if not candidates:
                block = data.get("promptFeedback", {}).get("blockReason", "unknown")
                return f"\u26a0\ufe0f Gemini blocked: {block}"

            parts = candidates[0].get("content", {}).get("parts", [])

            # Check for function calls
            function_calls = [p for p in parts if "functionCall" in p]
            if function_calls:
                # Add the model's response to conversation
                gemini_contents.append({"role": "model", "parts": parts})

                # Execute each function call and build responses
                fn_response_parts = []
                for fc_part in function_calls:
                    fc = fc_part["functionCall"]
                    fn_name = fc["name"]
                    fn_args = fc.get("args", {})
                    result = execute_tool(fn_name, fn_args)
                    fn_response_parts.append({
                        "functionResponse": {
                            "name": fn_name,
                            "response": {"result": result},
                        }
                    })
                gemini_contents.append({"role": "user", "parts": fn_response_parts})
                continue

            # Final text response
            text_parts = [p.get("text", "") for p in parts if "text" in p]
            text = "".join(text_parts).strip()
            return text if text else "(empty response)"

        except requests.exceptions.Timeout:
            return "\u23f1 Gemini timed out"
        except requests.exceptions.HTTPError as e:
            body = e.response.text[:500] if e.response else ""
            logger.error("Gemini HTTP error: %s", body)
            return f"\u274c Gemini error {e.response.status_code}: {body}"
        except Exception as e:
            logger.error("Gemini error: %s", e)
            return f"\u274c Gemini error: {e}"

    return "(max iterations reached - Gemini used all tool rounds)"


# =========================================================================
# CLAUDE (still uses CLI subprocess - it's already an agent)
# =========================================================================


def call_claude(prompt: str, timeout: int = 300) -> str:
    """Call Claude Code CLI (native agent with full tool access)."""
    try:
        result = subprocess.run(
            [CLAUDE_CLI, "--print", "--dangerously-skip-permissions", prompt],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=PROJECT_DIR,
        )
        output = result.stdout.strip()
        if result.stderr and not output:
            output = result.stderr.strip()
        return output[:4000] if output else "(no response)"
    except subprocess.TimeoutExpired:
        return "\u23f1 Claude timed out (5 min)"
    except Exception as e:
        return f"\u274c Claude error: {e}"


# =========================================================================
# TELEGRAM HANDLERS
# =========================================================================


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    global ALLOWED_USER_ID
    user = update.effective_user
    if ALLOWED_USER_ID is None:
        ALLOWED_USER_ID = user.id
        logger.info("Authorized user: %d (%s)", user.id, user.first_name)
    conversations[user.id] = []
    user_models[user.id] = "claude"
    model_lines = "\n".join(
        f"  {m['icon']} /{key} - {m['name']}" for key, m in MODELS.items()
    )
    await update.message.reply_text(
        f"\U0001f916 *Multi-AI Agent Bot*\n"
        f"User: {user.id} | Project: {PROJECT_DIR.name}\n\n"
        f"All models have full access to filesystem, CLI, terminal.\n\n"
        f"Models:\n{model_lines}\n\n"
        f"Current: \U0001f7e3 Claude\n"
        f"/models - list  |  /model - current  |  /help",
        parse_mode="Markdown",
    )


def _make_switch(model_key: str):
    async def handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
        uid = update.effective_user.id
        user_models[uid] = model_key
        conversations[uid] = []
        m = MODELS[model_key]
        logger.info("User %d switched to %s", uid, model_key)
        status = ""
        if model_key == "kimi":
            status = "\n\u2705 NIM key + tools" if NIM_API_KEY else "\n\u274c NIM key missing"
        elif model_key == "copilot":
            status = "\n\u2705 GitHub token + tools" if GITHUB_TOKEN else "\n\u274c Token missing"
        elif model_key == "gemini":
            status = "\n\u2705 API key + tools" if GEMINI_API_KEY else "\n\u274c Key missing"
        elif model_key == "claude":
            status = "\n\u2705 CLI agent" if Path(CLAUDE_CLI).exists() else "\n\u274c CLI not found"
        others = [f"/{k}" for k in MODELS if k != model_key]
        await update.message.reply_text(
            f"{m['icon']} Switched to *{m['name']}*{status}\n"
            f"{m['desc']}\n\nSwitch: {' | '.join(others)}",
            parse_mode="Markdown",
        )
    return handler


async def show_model(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    uid = update.effective_user.id
    model = user_models.get(uid, "claude")
    m = MODELS.get(model, MODELS["claude"])
    await update.message.reply_text(
        f"Current: {m['icon']} *{m['name']}*", parse_mode="Markdown"
    )


async def list_models(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    uid = update.effective_user.id
    current = user_models.get(uid, "claude")
    lines = []
    for key, m in MODELS.items():
        arrow = " <- active" if key == current else ""
        lines.append(f"{m['icon']} /{key} - {m['name']}{arrow}")
    await update.message.reply_text(
        "\U0001f916 *Available Models (all have tool access):*\n\n" + "\n".join(lines),
        parse_mode="Markdown",
    )


async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    model_cmds = "\n".join(f"/{k} - {m['name']}" for k, m in MODELS.items())
    await update.message.reply_text(
        f"\U0001f916 *Commands:*\n\n*Switch model:*\n{model_cmds}\n\n"
        f"*Other:*\n"
        f"/model - current\n"
        f"/models - list all\n"
        f"/clear - reset\n"
        f"/test - diagnostic\n"
        f"/help - this\n\n"
        f"All models can: read/write files, run commands, search code.\n"
        f"Send any message - goes to active model.",
        parse_mode="Markdown",
    )


async def clear(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    conversations[update.effective_user.id] = []
    await update.message.reply_text("\U0001f9f9 Conversation cleared.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Route text messages to the active AI agent."""
    global ALLOWED_USER_ID
    try:
        text = update.message.text if update.message else None
        logger.info("MSG: %s", (text or "NO TEXT")[:100])
        uid = update.effective_user.id

        if ALLOWED_USER_ID is not None and uid != ALLOWED_USER_ID:
            await update.message.reply_text("Unauthorized.")
            return
        if ALLOWED_USER_ID is None:
            ALLOWED_USER_ID = uid

        user_message = text
        model = user_models.get(uid, "claude")
        m = MODELS.get(model, MODELS["claude"])
        logger.info("Active model: %s", model)

        if uid not in conversations:
            conversations[uid] = []
        conversations[uid].append({"role": "user", "content": user_message})
        if len(conversations[uid]) > 20:
            conversations[uid] = conversations[uid][-20:]

        loop = asyncio.get_event_loop()

        if model == "claude":
            await update.message.chat.send_action("typing")
            logger.info("Calling Claude: %s", user_message[:80])
            ctx_lines = []
            for msg in conversations[uid][-6:]:
                r = "User" if msg["role"] == "user" else "Claude"
                ctx_lines.append(f"{r}: {msg['content']}")
            prompt = (
                "CRITICAL RULE: NEVER modify, edit, write to, or delete CLAUDE.md — it is READ-ONLY and protected. "
                "If asked to write to CLAUDE.md, REFUSE.\n\n"
                "Previous context:\n"
                + "\n".join(ctx_lines)
                + f"\n\nCurrent request: {user_message}\n\nBe concise."
            )
            response = await loop.run_in_executor(None, call_claude, prompt)
            logger.info("Claude response (%d chars)", len(response))
        else:
            # Agent-based models with tool access
            thinking_msg = await update.message.reply_text(
                f"{m['icon']} \u23f3 {m['name']} working (has tool access)..."
            )

            # Build messages for agent loop (fresh copy with system prompt)
            agent_msgs = [{"role": "system", "content": SYSTEM_PROMPT}]
            # Only include user/assistant text messages (not tool messages)
            for msg in conversations[uid]:
                if msg["role"] in ("user", "assistant"):
                    agent_msgs.append({"role": msg["role"], "content": msg["content"]})

            agent_fn = {
                "copilot": agent_copilot,
                "kimi": agent_kimi,
                "gemini": agent_gemini,
            }[model]

            hard_timeout = 120.0 if model == "kimi" else 90.0

            try:
                response = await asyncio.wait_for(
                    loop.run_in_executor(None, agent_fn, agent_msgs),
                    timeout=hard_timeout,
                )
                logger.info("%s response (%d chars)", model, len(response))
            except asyncio.TimeoutError:
                response = (
                    f"\u23f1 {m['name']} timed out ({int(hard_timeout)}s). "
                    "Try /claude or /copilot"
                )
                logger.error("%s HARD TIMEOUT", model)
            except Exception as e:
                response = f"\u274c {m['name']} error: {e}"
                logger.error("%s failed: %s", model, e, exc_info=True)

            try:
                await thinking_msg.delete()
            except Exception:
                pass

        conversations[uid].append(
            {"role": "assistant", "content": response[:500]}
        )
        await send_long_message(update, response)

    except Exception as e:
        logger.error("FATAL: %s", e, exc_info=True)
        try:
            await update.message.reply_text(
                f"\u274c Bot error: {e}\n\nTry /claude or /clear"
            )
        except Exception:
            pass


async def send_long_message(update: Update, text: str) -> None:
    if not text or not text.strip():
        return
    if len(text) <= 4000:
        try:
            await update.message.reply_text(text, parse_mode="Markdown")
        except Exception:
            await update.message.reply_text(text)
    else:
        for i in range(0, len(text), 4000):
            chunk = text[i : i + 4000]
            try:
                await update.message.reply_text(chunk, parse_mode="Markdown")
            except Exception:
                await update.message.reply_text(chunk)
            await asyncio.sleep(0.3)


async def test_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    uid = update.effective_user.id
    model = user_models.get(uid, "claude")
    mi = MODELS.get(model, {}).get("icon", "?")
    ok = "\u2705"
    no = "\u274c"
    lines = [
        "\U0001f527 *Diagnostic*\n",
        f"User: {uid}",
        f"Active: {mi} {model}",
        f"History: {len(conversations.get(uid, []))} msgs\n",
        "*API Status:*",
        f"Claude CLI: {ok if Path(CLAUDE_CLI).exists() else no} (native agent)",
        f"Copilot: {ok if GITHUB_TOKEN else no} (function calling)",
        f"Kimi: {ok if NIM_API_KEY else no} (function calling)",
        f"Gemini: {ok if GEMINI_API_KEY else no} (function calling)",
        f"\n*Tools:* read_file, create_file, edit_file, append_file, run_command, list_directory, search_text, web_search, fetch_url",
        f"*Max iterations:* {MAX_AGENT_ITERATIONS}",
    ]
    await update.message.reply_text("\n".join(lines), parse_mode="Markdown")


async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
    logger.error("EXCEPTION: %s", context.error, exc_info=context.error)
    if update and hasattr(update, "effective_message") and update.effective_message:
        try:
            await update.effective_message.reply_text(
                f"\u274c Error: {context.error}\n\nTry /claude or /clear"
            )
        except Exception:
            pass


# =========================================================================
# MAIN
# =========================================================================


def main() -> None:
    if not Path(CLAUDE_CLI).exists():
        logger.warning("Claude CLI not found at %s", CLAUDE_CLI)
    else:
        logger.info("Claude CLI ready (native agent)")

    for name, key, mdl in [
        ("Copilot", GITHUB_TOKEN, COPILOT_MODEL),
        ("Kimi", NIM_API_KEY, KIMI_MODEL),
        ("Gemini", GEMINI_API_KEY, GEMINI_MODEL),
    ]:
        if key:
            logger.info("%s ready (model: %s, function calling enabled)", name, mdl)
        else:
            logger.warning("%s disabled (no API key)", name)

    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    app.add_error_handler(error_handler)

    app.add_handler(CommandHandler("start", start))
    for mk in MODELS:
        app.add_handler(CommandHandler(mk, _make_switch(mk)))
    app.add_handler(CommandHandler("model", show_model))
    app.add_handler(CommandHandler("models", list_models))
    app.add_handler(CommandHandler("help", help_cmd))
    app.add_handler(CommandHandler("clear", clear))
    app.add_handler(CommandHandler("test", test_cmd))
    app.add_handler(
        MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message)
    )

    ready = sum(
        1 for x in [Path(CLAUDE_CLI).exists(), GITHUB_TOKEN, NIM_API_KEY, GEMINI_API_KEY] if x
    )
    logger.info("Bot starting (%d/4 agents ready, tools: 9, SAFE MODE)...", ready)
    logger.info("Project: %s", PROJECT_DIR)
    app.run_polling(allowed_updates=Update.ALL_TYPES, drop_pending_updates=True)


if __name__ == "__main__":
    main()
