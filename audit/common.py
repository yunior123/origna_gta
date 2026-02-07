#!/usr/bin/env python3
"""
Shared utilities for all audit scripts.
Handles API key loading, streaming requests, and report saving.
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


def run_streaming_audit(prompt, project_text, temperature=0.3, max_tokens=8192):
    """Send audit request to Kimi 2.5 and stream the response.
    
    Args:
        prompt: The audit prompt string
        project_text: Bundled file contents
        temperature: Model temperature (default 0.3 for precision)
        max_tokens: Max response tokens
    
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
