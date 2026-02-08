#!/usr/bin/env python3
"""API security audit: auth → authz → input validation → rate limiting → CORS → injection → key security.
Enriched with Stripe webhook security, Firebase Auth, Firestore rules, and Algolia key documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import run_enriched_audit
from prompt_api_security import API_SECURITY_AUDIT_PROMPT

API_SECURITY_FILES = [
    # Cloud Function entry point & route registration
    "functions/main.py",
    "functions/function_options.py",
    # ALL handlers (complete attack surface)
    "functions/handlers/payment_stripe.py",
    "functions/handlers/payment_airwallex.py",
    "functions/handlers/payment_providers.py",
    "functions/handlers/orders.py",
    "functions/handlers/products.py",
    "functions/handlers/admin.py",
    "functions/handlers/cron_jobs.py",
    # Auth & config
    "functions/config.py",
    "functions/utils.py",
    "functions/rate_limiter.py",
    # Input validation models
    "functions/models/base.py",
    "functions/models/user.py",
    "functions/models/product.py",
    "functions/models/order.py",
    # External service clients (key usage)
    "functions/algolia_service.py",
    "functions/email_service.py",
    # Firestore security rules
    "firestore.rules",
    # Schema (field names for injection testing)
    "functions/schema_constants.py",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="api_security",
        prompt=API_SECURITY_AUDIT_PROMPT,
        file_paths=API_SECURITY_FILES,
        prefix="api_security",
        workflow_name="API Security",
        emoji="🔒",
    )

if __name__ == "__main__":
    main()
