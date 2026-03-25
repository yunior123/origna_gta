---
name: notification-audit
description: "Deep audit of OrignaGTA notification pipeline: FCM push, Mailjet email, native triggers, and in-app notifications. Covers delivery guarantees, deduplication, rate limiting (20/day per user), perishable urgency alerts, PII leakage in logs, FCM token lifecycle, and email template XSS. Use when asked to 'audit notifications', 'check push', 'review email', 'notification audit', or similar."
---

# Notification Audit — OrignaGTA

Complete audit of the notification pipeline: push notifications (FCM), transactional email (Mailjet), native triggers, and in-app notification feed. Every checkpoint is grounded in real production failure modes.

## When To Use

- Before production deploy touching notification or email code
- After modifying order state transitions (notifications fire per state)
- When investigating missing/duplicate notifications
- When reviewing perishable product urgency flows
- Pre-release security review (PII in logs, XSS in templates)

## Files to Read

### Backend (Rust — OrignaBase)
```
orignabase/crates/ob-notifications/src/routes.rs       # Notification REST endpoints, delivery routing
orignabase/crates/ob-handlers/src/push/mod.rs           # FCM push sending, token management, rate limiting
orignabase/crates/ob-handlers/src/email/helpers.rs      # Mailjet email sending, template rendering
orignabase/crates/ob-handlers/src/native_triggers.rs    # Event-driven notification triggers per order state
orignabase/crates/ob-handlers/src/orders/status.rs      # Order state transitions (fires notifications)
orignabase/crates/ob-handlers/src/orders/returns.rs     # Return request notifications
orignabase/crates/ob-handlers/src/orders/shipping.rs    # Shipping/tracking notifications
```

### Flutter (Frontend)
```
origna_gta/lib/screens/notifications_screen.dart        # In-app notification feed UI
origna_gta/lib/main.dart                                # FCM initialization, foreground handler
```

---

## Audit Checkpoints

### 1. Notification Triggers per Order State

**Every order state transition MUST fire the correct notifications to the correct parties.**

| Order State | Buyer Notification | Seller Notification |
|-------------|-------------------|---------------------|
| `pending` | Order confirmation | New order alert |
| `confirmed` | Payment confirmed | -- |
| `shipped` | Shipped + tracking number | -- |
| `delivered` | Delivery confirmation | Payout scheduled |
| `cancelled` | Cancellation + refund info | Cancellation notice |
| Return `approved` | Return approved + refund | Return approved |
| Return `rejected` | Return rejected + reason | -- |
| Perishable `confirmed` | Perishable notice | URGENT: 24h ship deadline |

**Check:**
- [ ] `native_triggers.rs` maps EVERY state transition to notification(s)
- [ ] Buyer and seller get distinct messages (not same template)
- [ ] Perishable `confirmed` fires urgency alert to seller with 24h deadline
- [ ] `cancelled` notification includes refund amount and timeline
- [ ] `shipped` notification includes tracking number and carrier
- [ ] Return notifications include return request ID and reason
- [ ] No notification fires for invalid state transitions (e.g., `pending` -> `delivered`)

**Grep for:** `send_notification`, `send_push`, `send_email`, `notify_buyer`, `notify_seller`, `perishable`, `urgent`

### 2. FCM Push Delivery Pipeline

**Data flow: Order state change -> native_triggers.rs -> push/mod.rs -> FCM API -> device**

**Check:**
- [ ] FCM token stored per user device (not per user — multi-device support)
- [ ] Stale token cleanup: FCM returns `NotRegistered` -> token removed from DB
- [ ] Token refresh: new token from client overwrites old token for same device
- [ ] Push payload includes: `title`, `body`, `data` (for deep linking), `notification` (for tray)
- [ ] Deep link data includes enough context to navigate (order ID, screen name)
- [ ] Silent/data-only push used for background sync, not user-visible alerts
- [ ] FCM batch sending used when notifying multiple devices (not N individual calls)
- [ ] FCM HTTP v1 API used (not legacy API — deprecated June 2024)
- [ ] Service account key for FCM stored securely (not in source code)
- [ ] Error handling: FCM 429 (rate limit) -> exponential backoff
- [ ] Error handling: FCM 401 (auth failure) -> log + alert, don't retry infinitely

**Grep for:** `fcm`, `firebase_messaging`, `device_token`, `NotRegistered`, `send_multicast`, `access_token`

### 3. Rate Limiting (20/day per user)

**No user should receive more than 20 push notifications per day.**

**Check:**
- [ ] Counter stored per user per day (UTC boundary)
- [ ] Counter checked BEFORE sending, not after
- [ ] Counter incremented atomically (no race condition between check and send)
- [ ] Critical notifications (payment failure, security alert) bypass rate limit
- [ ] Rate limit applies to push only (not email, not in-app)
- [ ] Counter resets at UTC midnight (not user timezone)
- [ ] Admin notifications exempt from rate limit
- [ ] Rate limit logged when hit (for debugging "missing notification" complaints)

**Grep for:** `rate_limit`, `daily_limit`, `notification_count`, `MAX_DAILY`, `20`

### 4. Deduplication

**Same notification must not be sent twice for the same event.**

**Check:**
- [ ] Idempotency key per notification: `{event_type}:{entity_id}:{timestamp}` or similar
- [ ] Dedup check happens BEFORE queueing/sending
- [ ] Webhook retries don't cause duplicate notifications (webhook may fire 2-3x)
- [ ] Order state transition retries don't cause duplicate notifications
- [ ] `notification_log` or equivalent table records sent notifications
- [ ] Dedup window is reasonable (e.g., 1 hour, not forever)
- [ ] In-app notification feed doesn't show duplicates

**Grep for:** `idempotent`, `dedup`, `already_sent`, `notification_log`, `exists`

### 5. Mailjet Email Sending

**Transactional emails: order confirmation, shipping, returns, password reset.**

**Check:**
- [ ] Mailjet API key stored in env/secrets (not in source code)
- [ ] `From` address: `support@orignagta.ca` (matches SPF/DKIM records)
- [ ] Template IDs referenced by constant, not magic number
- [ ] Template variables sanitized (no raw HTML injection / XSS in user-provided fields)
- [ ] Specifically: product names, buyer names, seller names HTML-escaped before template injection
- [ ] Email sending is async / non-blocking (doesn't delay order state transition)
- [ ] Email failure doesn't block order processing (fire-and-forget with logging)
- [ ] Retry on transient Mailjet errors (5xx) with backoff
- [ ] No retry on permanent errors (invalid email, 4xx)
- [ ] Unsubscribe link present in marketing emails (CAN-SPAM / CASL compliance)
- [ ] Both EN and FR templates exist for bilingual Canada market

**Grep for:** `mailjet`, `send_email`, `template_id`, `from_email`, `support@orignagta.ca`, `html_escape`, `sanitize`

### 6. PII in Notification Logs

**Notification logs must NEVER contain PII in plaintext.**

**Check:**
- [ ] Log entries contain: notification type, recipient user ID, status, timestamp
- [ ] Log entries do NOT contain: email address, phone number, name, address
- [ ] Push payload logged at DEBUG level only (not INFO/WARN/ERROR)
- [ ] Email body not logged (only template ID + status)
- [ ] FCM token not logged in full (truncate to first 10 chars if needed)
- [ ] Sentry breadcrumbs don't capture notification content

**Grep for:** `log::`, `tracing::`, `info!`, `debug!`, `warn!`, `error!`, `sentry`, `email`, `phone`, `address`

### 7. Email Template Security (XSS)

**User-supplied data injected into email templates must be sanitized.**

**Check:**
- [ ] Product name: HTML-escaped before injection
- [ ] Buyer/seller display name: HTML-escaped
- [ ] Shipping address: HTML-escaped (especially city, street)
- [ ] Order notes / return reason: HTML-escaped
- [ ] No `{{{ }}}` (triple-brace unescaped) in Mailjet templates unless intentional
- [ ] URL parameters in email links are URL-encoded
- [ ] No JavaScript in email templates (email clients strip it, but defense in depth)

### 8. Perishable Urgency Alerts

**Perishable products must trigger 24h urgency flow on order confirmation.**

**Check:**
- [ ] `confirmed` state for perishable order triggers seller urgency push + email
- [ ] Urgency alert includes: order ID, product name, delivery deadline
- [ ] If seller doesn't ship within 24h: escalation notification to admin
- [ ] Buyer notified if perishable order not shipped within deadline
- [ ] Perishable flag checked from `products` table `isPerishable` field
- [ ] Urgency cron job or scheduled task exists to check unshipped perishable orders

**Grep for:** `perishable`, `urgent`, `24h`, `deadline`, `escalat`, `isPerishable`

### 9. In-App Notification Feed

**Flutter notification screen displays notification history.**

**Check:**
- [ ] Notifications fetched with pagination (not all at once)
- [ ] Read/unread status tracked per notification per user
- [ ] Mark-as-read on tap (not on screen load)
- [ ] Unread badge count on nav bar/icon
- [ ] Pull-to-refresh supported
- [ ] Empty state shown when no notifications
- [ ] Notification tap navigates to relevant screen (order detail, return detail, etc.)
- [ ] Old notifications cleaned up (TTL or max count)

---

## Severity Guide

| Severity | Criteria | Example |
|----------|----------|---------|
| **P0 Critical** | Notification causes data corruption or security breach | XSS in email template; PII logged to Sentry |
| **P1 High** | Notification missing for critical event or sent to wrong party | Buyer not notified of cancellation; seller gets buyer's refund email |
| **P2 Medium** | Duplicate notifications or rate limit bypass | Same "shipped" push sent 3 times; 50 pushes in one day |
| **P3 Low** | Cosmetic or minor UX issue | Wrong icon on push; notification feed shows stale count |

## Output Format

For each finding:
```
## [P0/P1/P2/P3] — Title
- **File**: path/to/file.rs:line
- **Issue**: What's wrong
- **Impact**: What could happen
- **Fix**: Specific code change needed
```
