#!/usr/bin/env python3
"""
Shared utilities for all audit scripts.
Handles API key loading, streaming requests, report saving, and doc crawling.
"""
import os
import sys
import json
import requests
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
MODEL = "moonshotai/kimi-k2.5"

# Lazy import to avoid circular dependencies
_doc_crawler = None
def _get_doc_crawler():
    global _doc_crawler
    if _doc_crawler is None:
        from doc_crawler import crawl_docs_for_audit
        _doc_crawler = crawl_docs_for_audit
    return _doc_crawler


def load_api_key():
    """Load NVIDIA NIM API key from environment or functions/.env file."""
    key = os.getenv("NVIDIA_NIM_API_KEY")
    if key:
        return key

    env_path = PROJECT_ROOT / "functions" / ".env"
    if env_path.exists():
        for line in env_path.read_text().splitlines():
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            if k.strip() == "NVIDIA_NIM_API_KEY":
                return v.strip()

    print("ERROR: NVIDIA_NIM_API_KEY not found.")
    print("Set it as env var or add it to functions/.env")
    sys.exit(1)


def bundle_targeted_files(file_paths, max_chars=200_000):
    """Bundle specific files into a single string for the audit prompt.
    
    Args:
        file_paths: List of Path objects or strings (absolute or relative to PROJECT_ROOT)
        max_chars: Maximum characters to include
    
    Returns:
        Bundled string with file contents
    """
    content = []
    total = 0
    found = 0
    missing = []

    for f in file_paths:
        path = Path(f) if Path(f).is_absolute() else PROJECT_ROOT / f
        if not path.exists():
            missing.append(str(f))
            continue
        try:
            text = path.read_text(errors="ignore")
        except Exception:
            missing.append(str(f))
            continue
        
        # Use relative path for display
        try:
            rel = path.relative_to(PROJECT_ROOT)
        except ValueError:
            rel = path
        
        block = f"\n\n### FILE: {rel}\n```\n{text}\n```"
        if total + len(block) > max_chars:
            remaining = len(file_paths) - found
            content.append(f"\n\n[TRUNCATED — {remaining} files omitted due to size limit]")
            break
        content.append(block)
        total += len(block)
        found += 1

    if missing:
        print(f"  ⚠️  Missing files: {', '.join(missing)}")
    
    return "".join(content)


def run_streaming_audit(prompt, project_text, temperature=0.3, max_tokens=32768):
    """Send audit request to Kimi 2.5 and stream the response.
    
    Args:
        prompt: The audit prompt string
        project_text: Bundled file contents
        temperature: Model temperature (default 0.3 for precision)
        max_tokens: Max response tokens (default 32768 for complete reports)
    
    Returns:
        The complete response text
    """
    api_key = load_api_key()

    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt + project_text}],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": True,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Accept": "text/event-stream",
        "Content-Type": "application/json",
    }

    print(f"Sending to {MODEL}...")
    res = requests.post(API_URL, headers=headers, json=payload, timeout=(30, 600), stream=True)
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

    print()
    return "".join(chunks)


def save_report(report, prefix, workflow_name):
    """Save audit report to output directory.
    
    Args:
        report: The report text
        prefix: File prefix (e.g. 'product', 'payment')
        workflow_name: Human-readable workflow name for the header
    """
    output_dir = SCRIPT_DIR / "output"
    output_dir.mkdir(exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = output_dir / f"{prefix}_report_{timestamp}.md"
    latest_path = output_dir / f"{prefix}_report.md"

    header = (
        f"# {workflow_name} Audit Report\n\n"
        f"**Generated:** {datetime.now().isoformat()}\n"
        f"**Model:** {MODEL}\n\n---\n\n"
    )
    full_report = header + report

    report_path.write_text(full_report)
    latest_path.write_text(full_report)

    print(f"\n{workflow_name} audit report saved:")
    print(f"  Latest:     {latest_path}")
    print(f"  Timestamped: {report_path}")


def run_enriched_audit(
    audit_type: str,
    prompt: str,
    file_paths: list,
    prefix: str,
    workflow_name: str,
    emoji: str = "🔍",
    crawl_docs: bool = True,
    max_doc_chars: int = 60_000,
    max_tokens: int = 32768,
    max_continuations: int = 3,
):
    """Run a complete audit with optional doc crawling enrichment.
    
    This is the main entry point for audit scripts. It:
    1. Bundles targeted project files
    2. Optionally crawls external provider documentation
    3. Sends everything to Kimi 2.5
    4. If the response is truncated, sends continuation requests
    5. Saves the complete report
    
    Args:
        audit_type: Key for doc_crawler.DOC_URLS (e.g. 'payment', 'auth')
        prompt: The audit prompt string
        file_paths: List of project file paths to bundle
        prefix: Report file prefix
        workflow_name: Human-readable name for display
        emoji: Emoji for terminal output
        crawl_docs: Whether to crawl external documentation
        max_doc_chars: Max chars for crawled docs
        max_tokens: Max response tokens per request (default 32768)
        max_continuations: Max continuation requests if response is truncated
    """
    print(f"{emoji} {workflow_name} Audit (Kimi 2.5)")
    print("=" * 50)

    # 1. Bundle project files
    resolved = [PROJECT_ROOT / f for f in file_paths]
    print(f"Collecting {len(resolved)} targeted files...")
    project_text = bundle_targeted_files(resolved)
    print(f"Bundled {len(project_text):,} characters of project code")

    # 2. Crawl external documentation
    doc_text = ""
    if crawl_docs:
        try:
            crawl_fn = _get_doc_crawler()
            doc_text = crawl_fn(audit_type, max_total_chars=max_doc_chars)
            if doc_text:
                print(f"Total context: {len(project_text) + len(doc_text):,} characters")
        except Exception as e:
            print(f"  ⚠️  Doc crawling failed (continuing without docs): {e}")
            doc_text = ""

    # 3. Build full context
    full_context = project_text
    if doc_text:
        full_context += "\n\n" + "=" * 60 + "\n"
        full_context += "## EXTERNAL PROVIDER DOCUMENTATION (for reference)\n"
        full_context += "Use this documentation to validate the project implementation.\n"
        full_context += "=" * 60 + "\n"
        full_context += doc_text

    # 4. Run audit
    report = run_streaming_audit(prompt, full_context, max_tokens=max_tokens)

    # 5. Continuation loop — if the response was cut off, ask the model to continue
    for i in range(max_continuations):
        # Heuristic: response was truncated if it doesn't end with a section marker
        # or ends mid-sentence (no period/newline at end)
        stripped = report.rstrip()
        if not stripped:
            break
        last_chars = stripped[-100:] if len(stripped) > 100 else stripped
        # Check if the response appears complete
        ends_cleanly = (
            stripped.endswith('---')
            or stripped.endswith('```')
            or stripped.endswith('.')
            or stripped.endswith('|')
            or '## 10.' in last_chars  # Reached final section
            or 'HIGH-PRIORITY FIXES' in last_chars.upper()
            or 'PRIORITY FIXES' in last_chars.upper()
        )
        if ends_cleanly:
            break

        print(f"\n⚠️  Response appears truncated. Requesting continuation {i + 1}/{max_continuations}...")
        continuation_prompt = (
            "Your previous response was cut off. Continue EXACTLY where you left off. "
            "Do NOT repeat any content. Here is the end of your previous response:\n\n"
            f"...{stripped[-500:]}\n\n"
            "Continue from here:"
        )
        continuation = run_streaming_audit(
            continuation_prompt, "", max_tokens=max_tokens
        )
        if not continuation.strip():
            break
        report += continuation

    # 6. Save
    save_report(report, prefix, workflow_name)
