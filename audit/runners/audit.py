#!/usr/bin/env python3
"""
Code auditor using Kimi 2.5 via NVIDIA NIM API.
Reads NVIDIA_NIM_API_KEY from functions/.env or environment.
"""
import os
import sys
import json
import requests
from datetime import datetime
from pathlib import Path

# Resolve project root (grandparent: runners/ → audit/ → project root)
SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
PROJECT_ROOT = AUDIT_DIR.parent

sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))
from collect_files import collect_project_files, bundle_files
from prompt import AUDIT_PROMPT

API_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
MODEL = "moonshotai/kimi-k2.5"


def load_api_key():
    """Load API key from environment or functions/.env file."""
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


def run_audit(project_root):
    api_key = load_api_key()

    files = collect_project_files(project_root)
    print(f"Collected {len(files)} files for audit")

    project_text = bundle_files(files)
    print(f"Bundled {len(project_text):,} characters")

    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": AUDIT_PROMPT + project_text,
            }
        ],
        "temperature": 0.3,
        "max_tokens": 8192,
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

    print()  # newline after streaming
    return "".join(chunks)


def main():
    root = str(PROJECT_ROOT)
    report = run_audit(root)

    output_dir = SCRIPT_DIR / "output"
    output_dir.mkdir(exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = output_dir / f"report_{timestamp}.md"

    # Also write latest
    latest_path = output_dir / "report.md"

    header = f"# Audit Report\n\n**Generated:** {datetime.now().isoformat()}\n**Model:** {MODEL}\n\n---\n\n"
    full_report = header + report

    report_path.write_text(full_report)
    latest_path.write_text(full_report)

    print(f"\nAudit report saved:")
    print(f"  Latest:     {latest_path}")
    print(f"  Timestamped: {report_path}")


if __name__ == "__main__":
    main()
