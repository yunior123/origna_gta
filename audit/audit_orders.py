#!/usr/bin/env python3
"""Order lifecycle audit: creation → state transitions → seller actions → shipping → confirmation → auto-capture."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import PROJECT_ROOT, bundle_targeted_files, run_streaming_audit, save_report
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
    print("📋 Order Lifecycle Audit (Kimi 2.5)")
    print("=" * 50)
    file_paths = [PROJECT_ROOT / f for f in ORDERS_FILES]
    print(f"Collecting {len(file_paths)} targeted files...")
    project_text = bundle_targeted_files(file_paths)
    print(f"Bundled {len(project_text):,} characters")
    report = run_streaming_audit(ORDERS_AUDIT_PROMPT, project_text)
    save_report(report, "orders", "Order Lifecycle")

if __name__ == "__main__":
    main()
