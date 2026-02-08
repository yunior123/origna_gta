#!/usr/bin/env python3
"""Product lifecycle audit: creation → cart → checkout → shipping → delivery → capture → payout.
Enriched with Algolia, Cloudflare R2, and Firestore documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from common import run_enriched_audit
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
    run_enriched_audit(
        audit_type="product",
        prompt=PRODUCT_AUDIT_PROMPT,
        file_paths=PRODUCT_FILES,
        prefix="product",
        workflow_name="Product Lifecycle",
        emoji="🔍",
    )

if __name__ == "__main__":
    main()
