#!/usr/bin/env python3
"""State management & MVVM audit: Riverpod providers → state classes → ViewModels → screens.
Validates architectural compliance with strict MVVM pattern."""
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
AUDIT_DIR = SCRIPT_DIR.parent
sys.path.insert(0, str(AUDIT_DIR))
sys.path.insert(0, str(AUDIT_DIR / "prompts"))

from common import run_enriched_audit
from prompt_state_mgmt import STATE_MGMT_AUDIT_PROMPT

STATE_MGMT_FILES = [
    # Riverpod providers
    "origna_gta/lib/features/auth/auth_provider.dart",
    "origna_gta/lib/features/checkout/checkout_provider.dart",
    "origna_gta/lib/features/orders/orders_provider.dart",
    "origna_gta/lib/features/products/products_provider.dart",
    "origna_gta/lib/features/cart/cart_provider.dart",
    "origna_gta/lib/features/terms/terms_provider.dart",
    # State classes
    "origna_gta/lib/features/auth/login_state.dart",
    "origna_gta/lib/features/checkout/checkout_state.dart",
    "origna_gta/lib/features/orders/seller_orders_state.dart",
    "origna_gta/lib/features/home/home_state.dart",
    "origna_gta/lib/features/profile/profile_state.dart",
    "origna_gta/lib/features/profile/address_state.dart",
    "origna_gta/lib/features/products/add_product_state.dart",
    "origna_gta/lib/features/products/edit_product_state.dart",
    "origna_gta/lib/features/seller/seller_registration_state.dart",
    # ViewModels
    "origna_gta/lib/features/seller/seller_registration_view_model.dart",
    "origna_gta/lib/features/profile/profile_provider.dart",
    # Repositories (data access layer)
    "origna_gta/lib/core/repositories/auth_repository.dart",
    "origna_gta/lib/core/repositories/cart_repository.dart",
    "origna_gta/lib/core/repositories/order_repository.dart",
    "origna_gta/lib/core/repositories/product_repository.dart",
    # Services
    "origna_gta/lib/services/session_timeout_service.dart",
    "origna_gta/lib/services/conf_services.dart",
    # Models
    "origna_gta/lib/models/generated/base_models.dart",
    "origna_gta/lib/models/generated/order_models.dart",
    "origna_gta/lib/models/generated/product_models.dart",
    "origna_gta/lib/models/generated/user_models.dart",
    "CLAUDE.md",
]

def main():
    run_enriched_audit(
        audit_type="state_management",
        prompt=STATE_MGMT_AUDIT_PROMPT,
        file_paths=STATE_MGMT_FILES,
        prefix="state_mgmt",
        workflow_name="State Management & MVVM",
        emoji="🧠",
    )

if __name__ == "__main__":
    main()
