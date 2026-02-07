---
paths:
  - "firestore.rules"
  - "**/auth*"
  - "**/admin*"
  - "**/rate_limiter*"
  - "**/security*"
---

# Security Rules

## Principles
- **Assume attackers WILL use the app** — handle every edge case
- **Server-side validation for EVERYTHING** — never trust frontend
- **Price re-verification** — always re-fetch from Firestore before charging
- **Firestore rules are defense-in-depth** — backend validates first, rules are backup

## Mandatory Checks
- Self-purchase blocked (seller ≠ buyer)
- Role-gated operations (admin, seller, buyer)
- MFA required for role changes
- Rate limiting on auth endpoints
- Webhook HMAC signature verification
- Idempotency keys for payment operations
- Atomic stock operations (Firestore transactions)
- Suspended seller cascade (products deactivated)

## Audit Infrastructure
Targeted audit scripts in `audit/` send ~15 files per domain to Kimi K2.5:
- `audit_payment.py` — Payment flow audit
- `audit_orders.py` — Order lifecycle audit
- `audit_product.py` — Product CRUD audit
- `audit_seller.py` — Seller onboarding audit
- `audit_auth.py` — Auth & security audit
