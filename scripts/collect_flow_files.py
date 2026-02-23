#!/usr/bin/env python3
"""
collect_flow_files.py — Copies relevant source files for each workflow
into Desktop/origna_flows/<flow_name>/ for AI review.

Usage:
    python scripts/collect_flow_files.py
"""

import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DESKTOP = Path.home() / "Desktop" / "origna_flows"

# ── Workflow → files map (derived from docs/WORKFLOW_INDEX.md) ─────────────
FLOWS: dict[str, list[str]] = {
    "checkout_payment": [
        # Frontend
        "origna_gta/lib/features/cart/cart_provider.dart",
        "origna_gta/lib/features/checkout/checkout_provider.dart",
        "origna_gta/lib/screens/cart_screen.dart",
        "origna_gta/lib/screens/checkout_screen.dart",
        "origna_gta/lib/core/repositories/cart_repository.dart",
        "origna_gta/lib/core/repositories/order_repository.dart",
        "origna_gta/lib/screens/ordersuccess_screen.dart",
        # Backend
        "functions/handlers/payment_stripe.py",
        "functions/handlers/orders.py",
        "functions/services/shipping_service.py",
        "functions/schema_constants.py",
        # Schema / Rules
        "docs/database_schema.json",
        "firestore.rules",
        "docs/json_schemas/individual/Order.json",
        "origna_gta/lib/core/schema/schema_constants.dart",
    ],

    "order_lifecycle": [
        # Frontend
        "origna_gta/lib/features/orders/seller_orders_viewmodel.dart",
        "origna_gta/lib/features/orders/seller_orders_state.dart",
        "origna_gta/lib/features/orders/buyer_orders_viewmodel.dart",
        "origna_gta/lib/features/orders/orders_provider.dart",
        "origna_gta/lib/features/orders/shipping_approval_viewmodel.dart",
        "origna_gta/lib/screens/orders_screen.dart",
        "origna_gta/lib/screens/seller_orders_screen.dart",
        "origna_gta/lib/screens/shipping_approval_screen.dart",
        # Backend
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/handlers/cron_jobs.py",
        "functions/services/email_service.py",
        # Models
        "origna_gta/lib/models/generated/order_models.dart",
        "origna_gta/lib/models/generated/base_models.dart",
        "functions/models/order.py",
        "functions/models/base.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/Order.json",
        "firestore.rules",
    ],

    "product_lifecycle": [
        # Frontend
        "origna_gta/lib/features/products/add_product_viewmodel.dart",
        "origna_gta/lib/features/products/add_product_state.dart",
        "origna_gta/lib/features/products/edit_product_viewmodel.dart",
        "origna_gta/lib/features/products/edit_product_state.dart",
        "origna_gta/lib/features/products/product_detail_viewmodel.dart",
        "origna_gta/lib/features/products/product_actions_viewmodel.dart",
        "origna_gta/lib/features/products/products_provider.dart",
        "origna_gta/lib/features/products/product_rating_viewmodel.dart",
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/editproduct_screen.dart",
        "origna_gta/lib/screens/productdetails_screen.dart",
        "origna_gta/lib/screens/product_card_screen.dart",
        "origna_gta/lib/screens/productaddimages_screen.dart",
        "origna_gta/lib/core/repositories/product_repository.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/services/algolia_service.py",
        "functions/models/product.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/Product.json",
        "origna_gta/lib/models/generated/product_models.dart",
    ],

    "add_product": [
        # Core UI + ViewModel
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/productaddimages_screen.dart",
        "origna_gta/lib/features/products/add_product_viewmodel.dart",
        "origna_gta/lib/features/products/add_product_state.dart",
        # Warehouse support
        "origna_gta/lib/features/seller/warehouses_viewmodel.dart",
        # Repository + providers
        "origna_gta/lib/core/repositories/product_repository.dart",
        "origna_gta/lib/features/products/products_provider.dart",
        # Backend
        "functions/handlers/products.py",
        "functions/services/algolia_service.py",
        "functions/services/shipping_service.py",
        "functions/models/product.py",
        # Constants + schema
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "origna_gta/lib/models/generated/product_models.dart",
        "docs/json_schemas/individual/Product.json",
    ],

    "auth_seller_onboarding": [
        # Frontend
        "origna_gta/lib/features/auth/auth_provider.dart",
        "origna_gta/lib/features/auth/login_viewmodel.dart",
        "origna_gta/lib/features/auth/login_state.dart",
        "origna_gta/lib/features/seller/seller_registration_view_model.dart",
        "origna_gta/lib/features/seller/seller_registration_state.dart",
        "origna_gta/lib/features/seller/seller_account_status_viewmodel.dart",
        "origna_gta/lib/screens/login_screen.dart",
        "origna_gta/lib/screens/seller_registration_screen.dart",
        "origna_gta/lib/screens/seller_setup_screen.dart",
        "origna_gta/lib/screens/authwrapper_screen.dart",
        "origna_gta/lib/core/repositories/auth_repository.dart",
        "origna_gta/lib/core/repositories/user_repository.dart",
        # Backend
        "functions/handlers/admin.py",
        "functions/handlers/payment_stripe.py",
        "functions/models/user.py",
        "functions/services/rate_limiter.py",
        # Schema
        "docs/database_schema.json",
        "docs/json_schemas/individual/User.json",
        "firestore.rules",
    ],

    "email_notifications": [
        "functions/services/email_service.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
        "functions/handlers/cron_jobs.py",
    ],

    "cron_jobs": [
        "functions/handlers/cron_jobs.py",
        "functions/handlers/orders.py",
        "functions/handlers/payment_stripe.py",
    ],

    "search_discovery": [
        # Frontend
        "origna_gta/lib/features/home/home_viewmodel.dart",
        "origna_gta/lib/features/home/home_state.dart",
        "origna_gta/lib/screens/home_screen.dart",
        "origna_gta/lib/core/repositories/algolia_product_repository.dart",
        "origna_gta/lib/services/algolia_service.dart",
        # Backend
        "functions/services/algolia_service.py",
        "functions/handlers/products.py",
    ],

    "security": [
        "firestore.rules",
        "functions/services/rate_limiter.py",
        "functions/utils/helpers.py",
        "functions/handlers/admin.py",
        "origna_gta/lib/core/repositories/auth_repository.dart",
        "origna_gta/lib/features/auth/auth_provider.dart",
    ],

    "schema_consistency": [
        "docs/database_schema.json",
        "functions/schema_constants.py",
        "origna_gta/lib/core/schema/schema_constants.dart",
        "functions/models/base.py",
        "functions/models/order.py",
        "functions/models/product.py",
        "functions/models/user.py",
        "origna_gta/lib/models/generated/base_models.dart",
        "origna_gta/lib/models/generated/order_models.dart",
        "origna_gta/lib/models/generated/product_models.dart",
        "origna_gta/lib/models/generated/user_models.dart",
        # Individual JSON schemas
        "docs/json_schemas/individual/Order.json",
        "docs/json_schemas/individual/Product.json",
        "docs/json_schemas/individual/User.json",
    ],
}


def copy_flow(flow_name: str, file_paths: list[str]) -> tuple[int, int]:
    """Copy files for a flow into Desktop/origna_flows/<flow_name>/. Returns (copied, missing)."""
    dest_root = DESKTOP / flow_name
    if dest_root.exists():
        shutil.rmtree(dest_root)
    dest_root.mkdir(parents=True)

    copied = 0
    missing = 0
    for rel in file_paths:
        src = REPO_ROOT / rel
        if not src.exists():
            print(f"  ⚠️  MISSING: {rel}")
            missing += 1
            continue
        # Flatten into dest preserving relative path structure
        dest = dest_root / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        copied += 1

    return copied, missing


def main() -> None:
    print(f"📂 Output: {DESKTOP}\n")
    total_copied = 0
    total_missing = 0

    for flow, files in FLOWS.items():
        copied, missing = copy_flow(flow, files)
        status = "✅" if missing == 0 else "⚠️ "
        print(f"{status} {flow:<30}  {copied} files copied  ({missing} missing)")
        total_copied += copied
        total_missing += missing

    print(f"\nDone — {total_copied} files copied, {total_missing} missing across {len(FLOWS)} flows.")
    print(f"📁 Open: {DESKTOP}")


if __name__ == "__main__":
    main()
