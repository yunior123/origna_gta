#!/usr/bin/env python3
"""Seller onboarding audit: registration → Stripe Connect → KYC → products → orders → payouts → suspension."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import PROJECT_ROOT, bundle_targeted_files, run_streaming_audit, save_report
from prompt_seller import SELLER_AUDIT_PROMPT

SELLER_FILES = [
    "functions/handlers/payment_stripe.py",
    "functions/handlers/admin.py",
    "functions/handlers/products.py",
    "functions/handlers/payment_providers.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/utils.py",
    "functions/models/user.py",
    "functions/models/product.py",
    "origna_gta/lib/screens/seller_orders_screen.dart",
    "origna_gta/lib/screens/seller_order_detail_screen.dart",
    "origna_gta/lib/features/seller/seller_provider.dart",
    "origna_gta/lib/features/auth/auth_provider.dart",
    "firestore.rules",
    "CLAUDE.md",
]

def main():
    print("🏪 Seller Onboarding Audit (Kimi 2.5)")
    print("=" * 50)
    file_paths = [PROJECT_ROOT / f for f in SELLER_FILES]
    print(f"Collecting {len(file_paths)} targeted files...")
    project_text = bundle_targeted_files(file_paths)
    print(f"Bundled {len(project_text):,} characters")
    report = run_streaming_audit(SELLER_AUDIT_PROMPT, project_text)
    save_report(report, "seller", "Seller Onboarding")

if __name__ == "__main__":
    main()
