#!/usr/bin/env python3
"""Seller onboarding audit: registration → Stripe Connect → KYC → products → orders → payouts → suspension.
Enriched with Stripe Connect Express and capabilities documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
from prompt_seller import SELLER_AUDIT_PROMPT

SELLER_FILES = [
    "functions/handlers/payment_stripe.py",
    "functions/handlers/admin.py",
    "functions/handlers/products.py",
    "functions/handlers/payment_providers.py",
    "functions/config.py",
    "functions/schema_constants.py",
    "functions/utils/helpers.py",
    "functions/models/user.py",
    "functions/models/product.py",
    "origna_gta/lib/screens/seller_orders_screen.dart",
    "origna_gta/lib/screens/seller_setup_screen.dart",
    "origna_gta/lib/features/seller/seller_registration_view_model.dart",
    "origna_gta/lib/features/auth/auth_provider.dart",
    "firestore.rules",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="seller",
        prompt=SELLER_AUDIT_PROMPT,
        file_paths=SELLER_FILES,
        prefix="seller",
        workflow_name="Seller Onboarding",
        emoji="🏪",
    )

if __name__ == "__main__":
    main()
