#!/usr/bin/env python3
"""Payment system audit: checkout → authorization → webhooks → capture → transfers → refunds → disputes.
Enriched with Stripe, Airwallex documentation crawling."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import run_enriched_audit
from prompt_payment import PAYMENT_AUDIT_PROMPT

PAYMENT_FILES = [
    "functions/handlers/payment_stripe.py",
    "functions/handlers/payment_airwallex.py",
    "functions/handlers/payment_providers.py",
    "functions/handlers/cron_jobs.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/rate_limiter.py",
    "functions/utils.py",
    "functions/models/order.py",
    "functions/models/product.py",
    "origna_gta/lib/features/checkout/checkout_provider.dart",
    "origna_gta/lib/features/checkout/checkout_state.dart",
    "firestore.rules",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="payment",
        prompt=PAYMENT_AUDIT_PROMPT,
        file_paths=PAYMENT_FILES,
        prefix="payment",
        workflow_name="Payment System",
        emoji="💳",
    )

if __name__ == "__main__":
    main()
