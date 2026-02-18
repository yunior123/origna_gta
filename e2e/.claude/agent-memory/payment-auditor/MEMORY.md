# Payment Auditor Memory

## Key Learnings (2026-02-18)

### Backend Payment Flow (auto-capture mode)
- `create_checkout_session` creates Stripe Checkout Session WITHOUT `capture_method: "manual"`
- Webhook `checkout.session.completed` sets `paymentStatus: "captured"` (never "authorized")
- `PLATFORM_FEE_PERCENT` in config.py is actually `0.025` (ratio), not `2.5` (percent)
- Platform fee applied to subtotal only (not shipping/tax): `round(subtotalCents * 0.025)`
- `totalAmountCents = subtotalCents + shippingCostCents + taxAmountCents`

### Country Validation Bug (CRITICAL)
- Backend: `country.lower() != "canada"` -- only accepts full name "Canada"
- `BusinessRules.ALLOWED_SHIPPING_COUNTRIES = {"Canada", "CA"}` exists but is NOT used in the check
- E2E test helpers default to `'CA'` which will be rejected
- See: [e2e-audit-findings.md](./e2e-audit-findings.md)

### Test Architecture
- E2E tests target `orignagta-dev` (deployed, not emulator)
- No direct Firestore writes -- all mutations via Cloud Functions
- `waitForOrderStatus` polls Firestore REST API every 3s
- Dev credentials are hardcoded in api-helpers.ts (security hygiene issue)

### Stripe Test Cards (verified correct)
- 4242424242424242 = success
- 4000000000000002 = decline
- 4000000000009995 = insufficient funds
- 4000002500003155 = 3DS required
