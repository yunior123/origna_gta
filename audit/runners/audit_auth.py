#!/usr/bin/env python3
"""Auth & security audit: login → sessions → roles → MFA → rate limiting → account deletion → rules.
Enriched with Firebase Auth and Firestore rules documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
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
    run_enriched_audit(
        audit_type="auth",
        prompt=AUTH_AUDIT_PROMPT,
        file_paths=AUTH_FILES,
        prefix="auth",
        workflow_name="Auth & Security",
        emoji="🔐",
    )

if __name__ == "__main__":
    main()
