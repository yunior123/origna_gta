# Deep Security & Business Logic Audit — 2026-03-18

## Critical Findings (9 Issues Found, 4 CRITICAL)

See `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/.claude/plans/AUDIT_CRITICAL_FINDINGS.md` for full report.

### Quick Index
- **CRITICAL #1**: Stock race condition (checkout.rs:468-480)
- **CRITICAL #2**: Free shipping threshold uses pre-coupon subtotal (orignabase_checkout_provider.dart:158)
- **CRITICAL #3**: Partial refund amount unbounded (webhooks.rs:424-490)
- **CRITICAL #4**: Stock restoration not atomic (webhooks.rs:900-950)

### Major Issues (5)
- Self-purchase check ID mismatch (checkout.rs:250)
- Subtotal tolerance too loose (1%) (checkout.rs:85)
- Webhook races redirect (payment capture timing)
- Coupon not refunded on payment failure
- Negative price validation

**All issues require pre-launch fixes.**
