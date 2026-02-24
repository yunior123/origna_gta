"""
Origna GTA Cloud Functions - Entry Point
Refactored architecture with modular handlers

All Firebase Cloud Functions are organized by domain:
- payment_stripe: Stripe payment processing
- products: Product CRUD + Algolia sync
- orders: Order lifecycle management
- admin: User roles + MFA + GDPR
- cron_jobs: Scheduled background tasks
"""

# Firebase Admin SDK initialization
# Stripe API key setup
import os

import firebase_admin

# ===============================================
# MONKEY-PATCH: firebase-functions 0.4.x crashes with KeyError: 'authtype'
# when Firestore on_document_updated triggers are invoked by service accounts.
# raw._get_attributes() returns a dict missing 'authtype' and 'authid'.
# See: https://github.com/firebase/firebase-functions-python/issues/187
# ===============================================
import stripe

_original_get_attributes = None


def _patch_cloud_event_get_attributes(self):
    """Inject missing 'authtype'/'authid' into Firestore trigger event attributes."""
    attrs = _original_get_attributes(self)
    if isinstance(attrs, dict):
        attrs.setdefault("authtype", "SERVICE")
        attrs.setdefault("authid", "")
    return attrs


try:
    from cloudevents.http.event import CloudEvent as _CE

    _original_get_attributes = _CE._get_attributes
    _CE._get_attributes = _patch_cloud_event_get_attributes
except Exception:
    pass  # Fail silently — worst case, the original bug remains

# Initialize Firebase Admin SDK BEFORE any handler imports — handlers may call
# firestore.client() or firebase_admin.auth at import time.
if not firebase_admin._apps:
    firebase_admin.initialize_app()

# ===============================================
# PAYMENT HANDLERS - STRIPE
# ===============================================
# ===============================================
# DIGITAL PRODUCT HANDLERS
# ===============================================
# ===============================================
# ADDRESS HANDLERS
# ===============================================
from handlers.addresses import get_address_suggestions  # noqa: E402

# ===============================================
# ADMIN HANDLERS
# ===============================================
from handlers.admin import (  # noqa: E402
    admin_mfa_disable,
    admin_mfa_enroll,
    admin_mfa_verify,
    admin_mfa_verify_backup,
    admin_update_product_stock,
    admin_delete_review,
    admin_flag_review,
    admin_refund_order,
    delete_account,
    e2e_get_mail_logs,
    export_my_data,
    suspend_seller,
    unsubscribe_email,
    unsuspend_seller,
    update_user_roles,
)
from handlers.chat import (  # noqa: E402
    get_or_create_chat,
    mark_messages_read,
    send_message,
)

# ===============================================
# CRON JOB HANDLERS
# ===============================================
from handlers.cron_jobs import (  # noqa: E402
    auto_archive_old_orders,
    auto_capture_confirmed_receipts,
    check_expired_authorizations,
    check_low_stock_alerts,
    cleanup_orphaned_r2_images,
    cleanup_stale_rate_limits,
    cleanup_stale_security_alerts,
    cleanup_stale_webhook_events,
    compute_seller_metrics,
    compute_trending_products,
    monitor_algolia_sync,
    retry_failed_algolia_syncs,
    revalidate_digital_product_urls,
    send_abandoned_cart_emails,
    sync_expired_subscriptions,
    escalate_stale_return_requests,
)
from handlers.digital import (  # noqa: E402
    activate_license,
    deactivate_license,
    generate_book_download_session,
    generate_software_download_session,
    get_book_redirect,
    get_software_redirect,
    verify_license,
)

# ===============================================
# ORDER HANDLERS
# ===============================================
from handlers.orders import (  # noqa: E402
    approve_return_request,
    approve_shipping_cost,
    cancel_order,
    confirm_order_receipt,
    create_return_request,
    on_order_status_changed,
    on_return_request_status_changed,
    refund_order_item,
    reject_return_request,
    update_item_status,
    update_order_status,
    update_shipping_cost,
)

# ===============================================
# PAYMENT PROVIDER MANAGEMENT
# ===============================================
from handlers.payment_providers import get_payment_providers, get_provider_status, update_payment_provider  # noqa: E402
from handlers.payment_stripe import (  # noqa: E402
    capture_payment,
    create_account_link,
    create_checkout_session,
    create_connect_account,
    get_connect_account_status,
    process_charge_refunded,
    process_dispute_closed,
    process_dispute_created,
    process_dispute_funds_reinstated,
    process_dispute_updated,
    stripe_webhook,
    verify_cart_prices,
)
from handlers.products import (  # noqa: E402
    admin_approve_product,
    admin_reject_product,
    answer_product_question,
    answer_review,
    ask_product_question,
    bulk_update_products,
    deactivate_supplier_platform,
    configure_algolia,
    create_warehouse,
    delete_product,
    delete_warehouse,
    get_product_questions,
    get_product_ratings_paginated,
    get_products_paginated,
    get_seller_products_paginated,
    get_seller_warehouses,
    on_product_created,
    on_product_deleted,
    on_product_updated,
    submit_product_rating,
    subscribe_stock_notification,
    unsubscribe_stock_notification,
    update_warehouse,
    upload_product_images,
    upload_review_images,
    delete_product_images,
    create_product_atomic,
    vote_review_helpful,
)
from handlers.coupons import (  # noqa: E402
    admin_create_coupon,
    apply_coupon,
)
from handlers.subscriptions import (  # noqa: E402
    cancel_subscription,
    create_subscription,
    get_subscription_status,
)
from handlers.users import (  # noqa: E402
    add_buyer_address,
    create_user_profile,
    delete_buyer_address,
    get_user_profile,
    set_default_buyer_address,
    update_buyer_address,
    update_email_consent,
    update_user_profile,
)

# ===============================================
# PRODUCT HANDLERS
# ===============================================
# ===============================================
# SHIPPING CALCULATION — Canonical source is services/shipping_service.py
# This wrapper re-exports calculate_shipping_cost for external HTTP callers.
# The checkout flow (payment_stripe.py) imports directly from services.shipping_service.
# ===============================================
from services.shipping_service import calculate_shipping_cost  # noqa: E402, F811

# Initialize Sentry for production error monitoring
from config import init_sentry  # noqa: E402

init_sentry()


# Lazy initialization of Stripe API key
def _init_stripe():
    """Initialize Stripe API key lazily"""
    if not stripe.api_key:
        from config import get_stripe_secret_key

        stripe.api_key = get_stripe_secret_key()


# Only initialize in production (not in test environment)
if os.environ.get("TESTING") != "true":
    import contextlib

    with contextlib.suppress(Exception):
        _init_stripe()


# Export all functions for Firebase deployment
__all__ = [
    # Address autocomplete proxy
    "get_address_suggestions",
    # Stripe payments
    "create_checkout_session",
    "verify_cart_prices",
    "stripe_webhook",
    "capture_payment",
    "create_connect_account",
    "get_connect_account_status",
    "create_account_link",
    # Premium subscriptions
    "create_subscription",
    "cancel_subscription",
    "get_subscription_status",
    # Chat (premium feature)
    "get_or_create_chat",
    "mark_messages_read",
    "send_message",
    # Dispute handlers
    "process_charge_refunded",
    "process_dispute_created",
    "process_dispute_closed",
    "process_dispute_updated",
    "process_dispute_funds_reinstated",
    # Products
    "upload_product_images",
    "upload_review_images",
    "delete_product_images",
    "create_product_atomic",
    "delete_product",
    "submit_product_rating",
    "configure_algolia",
    "admin_approve_product",
    "admin_reject_product",
    "get_products_paginated",
    "get_seller_products_paginated",
    "get_product_ratings_paginated",
    "on_product_created",
    "on_product_updated",
    "on_product_deleted",
    # Back-in-stock (TASK 07)
    "subscribe_stock_notification",
    "unsubscribe_stock_notification",
    # Product Q&A (TASK 09)
    "ask_product_question",
    "answer_product_question",
    "get_product_questions",
    # Seller review reply (N-03)
    "answer_review",
    # Review helpfulness voting (N-04)
    "vote_review_helpful",
    # Bulk seller operations (N-08)
    "bulk_update_products",
    # Admin supplier platform deactivation
    "deactivate_supplier_platform",
    # Coupon / promo codes (N-07)
    "apply_coupon",
    "admin_create_coupon",
    # Warehouses
    "create_warehouse",
    "update_warehouse",
    "delete_warehouse",
    "get_seller_warehouses",
    # Orders
    "confirm_order_receipt",
    "update_order_status",
    "update_item_status",
    "refund_order_item",
    "cancel_order",
    "approve_shipping_cost",
    "update_shipping_cost",
    "on_order_status_changed",
    "on_return_request_status_changed",
    "create_return_request",
    "approve_return_request",
    "reject_return_request",
    # Admin
    "update_user_roles",
    "suspend_seller",
    "unsuspend_seller",
    "admin_update_product_stock",
    "admin_delete_review",
    "admin_flag_review",
    "admin_refund_order",
    "admin_mfa_enroll",
    "admin_mfa_verify",
    "admin_mfa_verify_backup",
    "admin_mfa_disable",
    "delete_account",
    "export_my_data",
    "unsubscribe_email",
    "e2e_get_mail_logs",
    # User Profile
    "add_buyer_address",
    "create_user_profile",
    "delete_buyer_address",
    "get_user_profile",
    "set_default_buyer_address",
    "update_buyer_address",
    "update_email_consent",
    "update_user_profile",
    # Payment Provider Management
    "get_payment_providers",
    "update_payment_provider",
    "get_provider_status",
    # Cron jobs
    "auto_capture_confirmed_receipts",
    "check_expired_authorizations",
    "auto_archive_old_orders",
    "monitor_algolia_sync",
    "revalidate_digital_product_urls",
    "cleanup_stale_rate_limits",
    "cleanup_orphaned_r2_images",
    "cleanup_stale_webhook_events",
    "cleanup_stale_security_alerts",
    "retry_failed_algolia_syncs",
    "check_low_stock_alerts",
    "send_abandoned_cart_emails",
    "compute_seller_metrics",
    # Trending products
    "compute_trending_products",
    "sync_expired_subscriptions",
    "escalate_stale_return_requests",
    # Shipping
    "calculate_shipping_cost",
    # Digital products
    "activate_license",
    "deactivate_license",
    "generate_book_download_session",
    "generate_software_download_session",
    "get_book_redirect",
    "get_software_redirect",
    "verify_license",
]

print(f"""
╔══════════════════════════════════════════════╗
║  Origna GTA Cloud Functions - Initialized   ║
║  Total Functions: {len(__all__)}                        ║
║  Architecture: Modular Handlers              ║
╚══════════════════════════════════════════════╝
""")
