# Coupon & Discount Auditor Memory

## Critical Architecture Decisions

### Pre-reservation Pattern (payment_stripe.py lines 1427-1473)
- Coupons are atomically pre-reserved in a transaction BEFORE Stripe session creation
- Increments both global `usedCount` and per-user `useCount` in same transaction
- If Stripe fails, rollback via `_rollback_checkout()` decrements the counts
- Order doc has `couponPrereserved: true` flag to prevent double-redemption in webhook

### Seller-Scoped Coupon Discount Calculation (payment_stripe.py lines 986-998)
- Platform-wide coupons: discount applies to full cart subtotal
- Seller-scoped coupons: discount only applies to that seller's items
- Critical for multi-seller carts to prevent over-discounting

### Validation Flow
1. `apply_coupon` (client preview) - non-binding validation
2. `create_checkout_session` re-validates at checkout time (authoritative)
3. `redeem_coupon` only called if `couponPrereserved` is false (legacy orders)

## Key Vulnerabilities Found

### Race Conditions
- Pre-reservation pattern prevents concurrent redemptions exceeding limits
- Without transaction: two users could both pass validation and exceed maxUsesTotal

### Expiry Check Gaps
- `redeem_coupon` re-checks expiry inside transaction (lines 226-238)
- But `_coupon_within_limits` helper in payment_stripe doesn't check expiry
- A coupon validated at 23:59:59 could expire before transaction executes

### Multi-Seller Cart Issues
- Seller-scoped coupons correctly compute discount only on that seller's items
- Platform fee calculated on post-discount amount (correct)