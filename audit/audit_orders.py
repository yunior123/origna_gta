#!/usr/bin/env python3
"""Order lifecycle audit: creation → state transitions → seller actions → shipping → confirmation → auto-capture.
Enriched with Stripe capture, webhook, and refund documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import run_enriched_audit
from prompt_orders import ORDERS_AUDIT_PROMPT

ORDERS_FILES = [
    "functions/handlers/orders.py",
    "functions/handlers/payment_stripe.py",
    "functions/handlers/cron_jobs.py",
    "functions/shipping_service.py",
    "functions/email_service.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/utils.py",
    "functions/models/order.py",
    "origna_gta/lib/features/orders/orders_provider.dart",
    "origna_gta/lib/features/orders/orders_state.dart",
    "origna_gta/lib/screens/order_details_screen.dart",
    "origna_gta/lib/screens/seller_order_detail_screen.dart",
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
