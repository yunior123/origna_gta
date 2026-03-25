---
name: subscription-audit
description: "Deep audit of OrignaGTA Stripe subscription lifecycle: create, update, cancel, reactivate, webhook handling, grace periods, proration, premium feature gating, and status propagation to Flutter. Price: $7.86 CAD/month. Covers invoice.payment_failed recovery, dunning, and seller premium status consistency. Use when asked to 'audit subscriptions', 'check premium', 'review subscription flow', or similar."
---

# Subscription Audit — OrignaGTA

Complete audit of the Stripe subscription lifecycle for seller premium accounts. $7.86 CAD/month. Covers creation through cancellation, webhook processing, grace periods, feature gating, and status propagation.

## When To Use

- Before production deploy touching subscription or premium code
- After modifying webhook handlers for subscription events
- When investigating premium status inconsistencies
- When reviewing grace period or dunning logic
- Pre-release billing audit

## Files to Read

### Backend (Rust — OrignaBase)
```
orignabase/crates/ob-handlers/src/payments/subscriptions.rs   # 3,198 LOC — entire subscription lifecycle
orignabase/crates/ob-handlers/src/payments/webhooks.rs         # Stripe webhook router, signature verification
orignabase/crates/ob-handlers/src/payments/checkout.rs         # Checkout session for subscription creation
orignabase/crates/ob-handlers/src/users/mod.rs                 # User/seller profile premium status field
orignabase/crates/ob-handlers/src/native_triggers.rs           # Subscription state change notifications
```

### Flutter (Frontend)
```
origna_gta/lib/features/seller/seller_account_status_viewmodel.dart  # Premium status display
origna_gta/lib/features/profile/orignabase_profile_viewmodel.dart    # Profile with subscription info
origna_gta/lib/core/schema/schema_constants.dart                     # Field names for subscription status
```

---

## Audit Checkpoints

### 1. Subscription Creation

**Flow: Seller taps "Go Premium" -> Checkout Session -> Stripe -> webhook confirms**

**Check:**
- [ ] Checkout Session created with `mode: 'subscription'` (not `payment`)
- [ ] Price: $7.86 CAD/month (`786` cents) — matches `BusinessRules.PREMIUM_SUBSCRIPTION_PRICE_CAD`
- [ ] `metadata.user_id` attached to Checkout Session for webhook correlation
- [ ] Only ONE active subscription per seller (prevent double-subscribe)
- [ ] Pre-check: if seller already has active subscription, block creation
- [ ] `success_url` and `cancel_url` point to correct Flutter screens
- [ ] Subscription NOT activated on redirect — wait for webhook confirmation
- [ ] `customer` object created/reused in Stripe (don't create duplicate customers)
- [ ] Stripe Customer ID stored on seller profile for future billing operations

**Grep for:** `subscription`, `mode`, `786`, `PREMIUM`, `customer`, `metadata.user_id`

### 2. Webhook Events — Subscription Lifecycle

**Every subscription webhook must be handled idempotently.**

| Webhook Event | Expected Action |
|--------------|-----------------|
| `customer.subscription.created` | Set `premiumStatus: active`, record `subscriptionId` on seller profile |
| `customer.subscription.updated` | Update status field, handle plan changes, proration |
| `customer.subscription.deleted` | Set `premiumStatus: cancelled`, revoke premium features |
| `invoice.paid` | Confirm ongoing subscription, update `lastPaymentAt` |
| `invoice.payment_failed` | Start grace period, notify seller, schedule retry |
| `customer.subscription.paused` | Set `premiumStatus: paused`, restrict premium features |
| `customer.subscription.resumed` | Restore `premiumStatus: active` |

**Check:**
- [ ] ALL 7 webhook events above are handled (not just created/deleted)
- [ ] Webhook signature verified (HMAC) before processing
- [ ] Idempotency: `webhook_events` table checked for duplicate event IDs
- [ ] `webhook_events.timestamp` field used (not `createdAt` — schema rule)
- [ ] Subscription ID extracted from webhook payload and matched to seller profile
- [ ] Status transitions are validated (don't go from `cancelled` to `active` via webhook alone)
- [ ] Unknown webhook events silently acknowledged (200 OK) — don't return 400

**Grep for:** `customer.subscription`, `invoice.paid`, `invoice.payment_failed`, `webhook_events`, `idempotent`

### 3. Grace Period on Payment Failure

**When `invoice.payment_failed` fires, seller keeps premium for a grace period.**

**Check:**
- [ ] Grace period duration defined (recommended: 7-14 days)
- [ ] Grace period start recorded on seller profile (`graceStartedAt` or similar)
- [ ] During grace period: premium features still active
- [ ] After grace period expires: premium features revoked
- [ ] Cron job or scheduled task checks for expired grace periods
- [ ] Seller notified on payment failure: email + push with "update payment method" CTA
- [ ] Reminder notifications: day 3, day 7, day before expiry
- [ ] Payment method update link: Stripe Customer Portal or Billing Portal URL
- [ ] If payment succeeds during grace period: grace period cleared, status restored
- [ ] If subscription cancelled during grace period: immediate revocation

**Grep for:** `grace_period`, `payment_failed`, `dunning`, `retry`, `billing_portal`, `update_payment`

### 4. Proration on Plan Changes

**If plan price changes or seller upgrades/downgrades mid-cycle.**

**Check:**
- [ ] Proration mode set: `create_prorations` or `always_invoice` (Stripe default: prorate)
- [ ] Upgrade: immediately effective, prorated charge for remainder of cycle
- [ ] Downgrade: effective at end of current period (no refund for remaining time)
- [ ] Price change propagated: if $7.86 changes, existing subscriptions updated on next renewal
- [ ] Proration amount calculated correctly (Stripe handles this, but verify no manual override)
- [ ] Preview proration before confirming (show seller what they'll be charged)

**Grep for:** `proration`, `prorate`, `upgrade`, `downgrade`, `subscription_update`

### 5. Cancellation Flow

**Seller cancels premium: immediate vs. end-of-period.**

**Check:**
- [ ] Default: cancel at end of billing period (`cancel_at_period_end: true`)
- [ ] Seller keeps premium features until period end
- [ ] `premiumStatus` set to `cancelling` (not `cancelled`) until period end
- [ ] At period end: `customer.subscription.deleted` webhook fires -> `premiumStatus: cancelled`
- [ ] Immediate cancellation option available (for admin or refund cases)
- [ ] After cancellation: seller can resubscribe (new Checkout Session)
- [ ] Resubscription doesn't create duplicate Stripe Customer
- [ ] Cancel reason captured (optional, for analytics)
- [ ] Cancellation confirmation email sent

**Grep for:** `cancel_at_period_end`, `cancel`, `delete_subscription`, `resubscribe`, `cancelling`

### 6. Premium Feature Gating

**Premium features must be consistently gated on both frontend and backend.**

**Check:**
- [ ] Backend: middleware or guard checks `premiumStatus == 'active'` on premium endpoints
- [ ] Frontend: UI checks premium status from seller profile provider
- [ ] Features gated behind premium (verify all are enforced):
  - [ ] Chat with buyers
  - [ ] Advanced analytics dashboard
  - [ ] Priority customer support
  - [ ] Bulk product upload
  - [ ] Custom storefront URL
  - [ ] (verify complete list against product requirements)
- [ ] Non-premium seller sees upgrade CTA, not broken features
- [ ] Backend rejects premium API calls from non-premium sellers (don't just hide UI)
- [ ] Premium status cached on frontend with reasonable TTL (not stale for hours)
- [ ] Status refresh on app foreground / resume

**Grep for:** `premiumStatus`, `is_premium`, `premium_guard`, `feature_gate`, `subscription_status`

### 7. Status Propagation to Flutter

**Premium status must flow correctly from Stripe -> OrignaBase -> Flutter.**

**Check:**
- [ ] Webhook updates `seller_profiles` record in SurrealDB
- [ ] Flutter fetches seller profile on login and on foreground
- [ ] Status values match between backend and frontend: `active`, `past_due`, `cancelled`, `paused`, `cancelling`
- [ ] No enum mismatch (Dart enum vs. Rust string vs. Stripe status)
- [ ] Riverpod provider for premium status uses `ref.watch()` (reactive)
- [ ] Status change triggers UI rebuild without manual refresh
- [ ] Optimistic UI: don't show premium features before webhook confirms
- [ ] Edge case: webhook delayed -> seller doesn't see premium for minutes -> acceptable UX?

**Grep for:** `premiumStatus`, `seller_profiles`, `AccountStatus`, `AsyncNotifier`, `ref.watch`

### 8. Subscription Status Values

**Stripe subscription statuses must map correctly to OrignaBase and Flutter.**

| Stripe Status | OrignaBase `premiumStatus` | UI Behavior |
|---------------|---------------------------|-------------|
| `active` | `active` | Full premium features |
| `past_due` | `past_due` | Grace period, show warning |
| `canceled` | `cancelled` | No premium, show upgrade CTA |
| `trialing` | `trialing` | Full features, show trial end date |
| `paused` | `paused` | Limited features, show resume CTA |
| `incomplete` | `incomplete` | Payment pending, show retry |
| `incomplete_expired` | `cancelled` | Payment failed permanently |
| `unpaid` | `past_due` | Similar to past_due handling |

**Check:**
- [ ] ALL Stripe statuses mapped (not just `active`/`canceled`)
- [ ] `incomplete` handled (Checkout started but not completed)
- [ ] `incomplete_expired` treated as cancellation
- [ ] `unpaid` vs `past_due` distinction clear
- [ ] Status stored as string (not boolean `isPremium` — loses granularity)
- [ ] Admin can override status manually (for support cases)

---

## Severity Guide

| Severity | Criteria | Example |
|----------|----------|---------|
| **P0 Critical** | Premium features accessible without payment, or double-billing | Feature gate bypassed; duplicate subscription created; webhook not verified |
| **P1 High** | Payment failure not handled, or status inconsistency | No grace period; cancelled seller still has premium; no dunning emails |
| **P2 Medium** | UX issue or missing edge case | No proration preview; stale premium status; missing cancellation email |
| **P3 Low** | Minor gap | Cancel reason not captured; trial not implemented yet |

## Output Format

For each finding:
```
## [P0/P1/P2/P3] — Title
- **File**: path/to/file.rs:line
- **Issue**: What's wrong
- **Impact**: What could happen (revenue loss, feature leak, billing dispute)
- **Fix**: Specific code change needed
```
