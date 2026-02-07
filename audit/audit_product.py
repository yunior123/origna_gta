#!/usr/bin/env python3
"""Product lifecycle audit: creation → cart → checkout → shipping → delivery → capture → payout."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import PROJECT_ROOT, bundle_targeted_files, run_streaming_audit, save_report
from prompt_product import PRODUCT_AUDIT_PROMPT

PRODUCT_FILES = [
    "functions/handlers/products.py",
    "functions/handlers/payment_stripe.py",
    "functions/handlers/orders.py",
    "functions/handlers/cron_jobs.py",
    "functions/shipping_service.py",
    "functions/algolia_service.py",
    "functions/email_service.py",
    "functions/schema_constants.py",
    "functions/config.py",
    "functions/utils.py",
    "functions/models/product.py",
    "functions/models/order.py",
    "origna_gta/lib/screens/addproduct_screen.dart",
    "origna_gta/lib/screens/editproduct_screen.dart",
    "origna_gta/lib/features/checkout/checkout_provider.dart",
    "origna_gta/lib/features/checkout/checkout_state.dart",
    "origna_gta/lib/services/cart_service.dart",
    "origna_gta/lib/models/models.dart",
    "origna_gta/lib/models/generated/base_models.dart",
    "firestore.rules",
    "firestore.indexes.json",
    "CLAUDE.md",
]

def main():
    print("🔍 Product Lifecycle Audit (Kimi 2.5)")
    print("=" * 50)
    file_paths = [PROJECT_ROOT / f for f in PRODUCT_FILES]
    print(f"Collecting {len(file_paths)} targeted files...")
    project_text = bundle_targeted_files(file_paths)
    print(f"Bundled {len(project_text):,} characters")
    report = run_streaming_audit(PRODUCT_AUDIT_PROMPT, project_text)
    save_report(report, "product", "Product Lifecycle")

if __name__ == "__main__":
    main()
