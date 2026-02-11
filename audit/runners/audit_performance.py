#!/usr/bin/env python3
"""Performance & scalability audit: queries → indexes → rate limits → cold starts → cost.
Enriched with Firestore best practices and Algolia documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
from prompt_performance import PERFORMANCE_AUDIT_PROMPT

PERFORMANCE_FILES = [
    # Backend handlers (query patterns)
    "functions/handlers/orders.py",
    "functions/handlers/products.py",
    "functions/handlers/payment_stripe.py",
    "functions/handlers/cron_jobs.py",
    "functions/handlers/admin.py",
    # Backend infra
    "functions/rate_limiter.py",
    "functions/config.py",
    "functions/main.py",
    "functions/function_options.py",
    "functions/algolia_service.py",
    "functions/shipping_service.py",
    # Firestore indexes & rules
    "firestore.indexes.json",
    "firestore.rules",
    # Frontend repositories (read patterns, pagination)
    "origna_gta/lib/core/repositories/product_repository.dart",
    "origna_gta/lib/core/repositories/order_repository.dart",
    "origna_gta/lib/core/repositories/algolia_product_repository.dart",
    "origna_gta/lib/core/repositories/cart_repository.dart",
    # Frontend services
    "origna_gta/lib/services/algolia_service.dart",
    # Schema (document structure = size)
    "functions/schema_constants.py",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="performance",
        prompt=PERFORMANCE_AUDIT_PROMPT,
        file_paths=PERFORMANCE_FILES,
        prefix="performance",
        workflow_name="Performance & Scalability",
        emoji="⚡",
    )

if __name__ == "__main__":
    main()
