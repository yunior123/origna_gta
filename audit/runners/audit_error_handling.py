#!/usr/bin/env python3
"""Error handling & resilience audit: exception handling → recovery → logging → monitoring.
Enriched with Stripe error handling and Firebase error documentation."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
from prompt_error_handling import ERROR_HANDLING_AUDIT_PROMPT

ERROR_HANDLING_FILES = [
    # Backend handlers (all endpoints)
    "functions/handlers/payment_stripe.py",
    "functions/handlers/payment_airwallex.py",
    "functions/handlers/payment_providers.py",
    "functions/handlers/orders.py",
    "functions/handlers/products.py",
    "functions/handlers/admin.py",
    "functions/handlers/cron_jobs.py",
    # Backend services (external API calls)
    "functions/services/email_service.py",
    "functions/services/shipping_service.py",
    "functions/services/algolia_service.py",
    "functions/services/rate_limiter.py",
    "functions/config.py",
    "functions/utils/helpers.py",
    # Backend models (validation)
    "functions/models/order.py",
    "functions/models/product.py",
    "functions/models/user.py",
    # Frontend repositories (data access + error handling)
    "origna_gta/lib/core/repositories/auth_repository.dart",
    "origna_gta/lib/core/repositories/order_repository.dart",
    "origna_gta/lib/core/repositories/product_repository.dart",
    "origna_gta/lib/core/repositories/cart_repository.dart",
    # Frontend providers (state + error propagation)
    "origna_gta/lib/features/checkout/checkout_provider.dart",
    "origna_gta/lib/features/orders/orders_provider.dart",
    "origna_gta/lib/features/auth/auth_provider.dart",
    "origna_gta/lib/features/products/products_provider.dart",
    # Frontend services
    "origna_gta/lib/services/session_timeout_service.dart",
    "origna_gta/lib/services/analytics_service.dart",
    # Entry point
    "functions/main.py",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="error_handling",
        prompt=ERROR_HANDLING_AUDIT_PROMPT,
        file_paths=ERROR_HANDLING_FILES,
        prefix="error_handling",
        workflow_name="Error Handling & Resilience",
        emoji="🛡️",
    )

if __name__ == "__main__":
    main()
