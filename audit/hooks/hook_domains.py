"""
💳 Payment System Audit Hook

Audits: checkout → authorization → webhooks → capture → transfers → refunds → disputes.
"""
from .base import BaseHook, register_hook
from .prompts import STRUCTURED_OUTPUT_INSTRUCTION, PROJECT_CONTEXT


@register_hook
class PaymentHook(BaseHook):
    hook_name = "payment"
    description = "Payment system: Stripe Connect, checkout, webhooks, capture, refunds"
    emoji = "💳"

    watch_patterns = [
        "functions/handlers/payment_*.py",
        "functions/handlers/cron_jobs.py",
        "functions/models/order.py",
        "origna_gta/lib/features/checkout/*",
        "firestore.rules",
    ]

    target_files = [
        "functions/handlers/payment_stripe.py",
        "functions/handlers/payment_airwallex.py",
        "functions/handlers/payment_providers.py",
        "functions/handlers/cron_jobs.py",
        "functions/config.py",
        "functions/schema_constants.py",
        "functions/rate_limiter.py",
        "functions/utils.py",
        "functions/models/order.py",
        "functions/models/product.py",
        "origna_gta/lib/features/checkout/checkout_provider.dart",
        "origna_gta/lib/features/checkout/checkout_state.dart",
        "firestore.rules",
    ]

    def get_prompt(self) -> str:
        return f"""You are a senior payment security engineer performing a DEEP audit of a payment system.

{PROJECT_CONTEXT}

## Focus Areas

1. **CHECKOUT INTEGRITY** — Price re-validation against Firestore? Stock reservation atomicity? Can amounts be tampered? Platform fee (2.5%) calculated server-side only?
2. **WEBHOOK SECURITY** — HMAC signature verification? Idempotency (duplicate event_id)? Replay attack resistance? All critical events handled?
3. **CAPTURE FLOW** — Can PaymentIntent be captured twice? Distributed lock / idempotency key? Authorization expiry (7 days)?
4. **TRANSFER/PAYOUT** — source_transaction linked? Transfer duplication? Firestore write failure after Stripe success?
5. **REFUND SAFETY** — Idempotent? Can refund exceed original amount? Transfers reversed on refund?
6. **DISPUTE HANDLING** — Auto-reverse transfers? Seller clawback? Security alerts?
7. **RACE CONDITIONS** — Concurrent capture? Concurrent refund + capture? Webhook ordering?
8. **CRON JOBS** — Auto-capture vs authorization expiry window? Retry logic? Thundering herd?
9. **PROVIDER SWITCHING** — Can payment start on Stripe and complete on Airwallex?

## Rules
- Assume adversarial users trying to steal money or get free products
- Create at least 30 payment attack scenarios
- Every finding must reference specific files and line numbers
- If something is solid, say it in ONE line

{STRUCTURED_OUTPUT_INSTRUCTION}

Project files:
"""


@register_hook
class AuthHook(BaseHook):
    hook_name = "auth"
    description = "Auth & security: login, sessions, roles, MFA, rate limiting, Firestore rules"
    emoji = "🔐"

    watch_patterns = [
        "functions/handlers/admin.py",
        "functions/rate_limiter.py",
        "functions/utils.py",
        "functions/models/user.py",
        "origna_gta/lib/features/auth/*",
        "origna_gta/lib/screens/login_screen.dart",
        "origna_gta/lib/screens/register_screen.dart",
        "origna_gta/lib/screens/admin_screen.dart",
        "firestore.rules",
    ]

    target_files = [
        "functions/handlers/admin.py",
        "functions/handlers/payment_stripe.py",
        "functions/rate_limiter.py",
        "functions/utils.py",
        "functions/config.py",
        "functions/schema_constants.py",
        "functions/models/user.py",
        "origna_gta/lib/features/auth/auth_provider.dart",
        "origna_gta/lib/features/auth/auth_state.dart",
        "origna_gta/lib/features/profile/profile_provider.dart",
        "origna_gta/lib/screens/login_screen.dart",
        "origna_gta/lib/screens/register_screen.dart",
        "origna_gta/lib/screens/admin_screen.dart",
        "firestore.rules",
    ]

    def get_prompt(self) -> str:
        return f"""You are a senior security engineer auditing the AUTHENTICATION & AUTHORIZATION system.

{PROJECT_CONTEXT}

## Focus Areas

1. **AUTHENTICATION** — Login without email verification? Session token replay? Firebase Auth rules?
2. **ROLE-BASED ACCESS** — Role assignment? Can user modify own role in Firestore? Roles checked in BOTH rules AND functions?
3. **ADMIN MFA** — TOTP secret storage? Timing attack on code comparison? MFA disable without MFA?
4. **RATE LIMITING** — Which endpoints? Per-user or per-IP? Bypass via IP rotation?
5. **FIRESTORE RULES** — Unauthenticated access? Cross-user data leakage? Admin-only field writes?
6. **ACCOUNT DELETION** — Complete (Auth + Firestore + subcollections)? Deleted user session reuse?
7. **INPUT SANITIZATION** — XSS, NoSQL injection, Unicode abuse?
8. **CLOUD FUNCTION SECURITY** — All callables check auth? Unauthenticated HTTP access?
9. **DATA ISOLATION** — Can user A read user B's profile/orders/cart?

## Rules
- Assume attackers with valid accounts trying privilege escalation
- Assume attackers with no account trying to access data
- Create at least 30 auth attack scenarios
- Every finding must reference specific files

{STRUCTURED_OUTPUT_INSTRUCTION}

Project files:
"""


@register_hook
class ProductHook(BaseHook):
    hook_name = "product"
    description = "Product lifecycle: creation, validation, cart, stock, Algolia sync"
    emoji = "📦"

    watch_patterns = [
        "functions/handlers/products.py",
        "functions/handlers/orders.py",
        "functions/algolia_service.py",
        "functions/shipping_service.py",
        "functions/models/product.py",
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/editproduct_screen.dart",
        "origna_gta/lib/features/checkout/*",
    ]

    target_files = [
        "functions/handlers/products.py",
        "functions/handlers/orders.py",
        "functions/handlers/cron_jobs.py",
        "functions/shipping_service.py",
        "functions/algolia_service.py",
        "functions/email_service.py",
        "functions/schema_constants.py",
        "functions/models/product.py",
        "functions/models/order.py",
        "origna_gta/lib/screens/addproduct_screen.dart",
        "origna_gta/lib/screens/editproduct_screen.dart",
        "origna_gta/lib/features/checkout/checkout_provider.dart",
        "origna_gta/lib/services/cart_service.dart",
        "origna_gta/lib/models/generated/product_models.dart",
        "firestore.rules",
    ]

    def get_prompt(self) -> str:
        return f"""You are a senior engineer auditing the PRODUCT LIFECYCLE of an e-commerce marketplace.

{PROJECT_CONTEXT}

## Focus Areas

1. **PRODUCT CREATION** — Server-side price/quantity validation? Image upload security? Category validation?
2. **STOCK MANAGEMENT** — Atomic stock decrements? Race conditions on concurrent purchases? Overselling prevention?
3. **CART INTEGRITY** — Can cart prices be tampered? Stale cart items (product deleted/updated)? Cart-to-checkout atomicity?
4. **ALGOLIA SYNC** — Index consistency with Firestore? Stale search results? Can a user craft malicious search queries?
5. **SHIPPING** — Canada-only validation server-side? Postal code format validation? Weight/dimensions manipulation?
6. **PRODUCT EDITING** — Can seller edit product with active orders? Price change after authorization?
7. **DATA VALIDATION** — Max lengths, allowed characters, negative prices, zero quantities?

## Rules
- Assume adversarial sellers uploading malicious products
- Assume adversarial buyers manipulating cart/checkout
- Every finding must reference specific files
- Create at least 20 product attack scenarios

{STRUCTURED_OUTPUT_INSTRUCTION}

Project files:
"""
