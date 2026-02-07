#!/usr/bin/env python3
"""Auth & security audit: login → sessions → roles → MFA → rate limiting → account deletion → rules."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import PROJECT_ROOT, bundle_targeted_files, run_streaming_audit, save_report
from prompt_auth import AUTH_AUDIT_PROMPT

AUTH_FILES = [
    "functions/handlers/admin.py",
    "functions/handlers/payment_stripe.py",
    "functions/rate_limiter.py",
    "functions/utils.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/models/user.py",
    "origna_gta/lib/features/auth/auth_provider.dart",
    "origna_gta/lib/features/auth/auth_state.dart",
    "origna_gta/lib/features/profile/profile_provider.dart",
    "origna_gta/lib/screens/login_screen.dart",
    "origna_gta/lib/screens/register_screen.dart",
    "origna_gta/lib/screens/admin_screen.dart",
    "firestore.rules",
    "CLAUDE.md",
]

def main():
    print("🔐 Auth & Security Audit (Kimi 2.5)")
    print("=" * 50)
    file_paths = [PROJECT_ROOT / f for f in AUTH_FILES]
    print(f"Collecting {len(file_paths)} targeted files...")
    project_text = bundle_targeted_files(file_paths)
    print(f"Bundled {len(project_text):,} characters")
    report = run_streaming_audit(AUTH_AUDIT_PROMPT, project_text)
    save_report(report, "auth", "Auth & Security")

if __name__ == "__main__":
    main()
