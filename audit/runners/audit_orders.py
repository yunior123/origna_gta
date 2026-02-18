#!/usr/bin/env python3
"""Order lifecycle audit: creation → state transitions → seller actions → shipping → confirmation → auto-capture.
Enriched with Stripe capture, webhook, and refund documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
from prompt_orders import ORDERS_AUDIT_PROMPT

ORDERS_FILES = [
    "functions/handlers/orders.py",
    "functions/handlers/payment_stripe.py",
    "functions/handlers/cron_jobs.py",
    "functions/services/shipping_service.py",
    "functions/services/email_service.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/utils/helpers.py",
    "functions/models/order.py",
    "origna_gta/lib/features/orders/orders_provider.dart",
    "origna_gta/lib/features/orders/seller_orders_state.dart",
    "origna_gta/lib/screens/orders_screen.dart",
    "origna_gta/lib/screens/shipping_approval_screen.dart",
    "origna_gta/lib/screens/seller_orders_screen.dart",
    "firestore.rules",
    "firestore.indexes.json",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="orders",
        prompt=ORDERS_AUDIT_PROMPT,
        file_paths=ORDERS_FILES,
        prefix="orders",
        workflow_name="Order Lifecycle",
        emoji="📋",
    )

if __name__ == "__main__":
    main()
