#!/usr/bin/env python3
"""Payment system audit: checkout → authorization → webhooks → capture → transfers → refunds → disputes."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import PROJECT_ROOT, bundle_targeted_files, run_streaming_audit, save_report
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
    print("💳 Payment System Audit (Kimi 2.5)")
    print("=" * 50)
    file_paths = [PROJECT_ROOT / f for f in PAYMENT_FILES]
    print(f"Collecting {len(file_paths)} targeted files...")
    project_text = bundle_targeted_files(file_paths)
    print(f"Bundled {len(project_text):,} characters")
    report = run_streaming_audit(PAYMENT_AUDIT_PROMPT, project_text)
    save_report(report, "payment", "Payment System")

if __name__ == "__main__":
    main()
