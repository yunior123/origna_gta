# E2E Payment Test Audit Findings (2026-02-18)

## CRITICAL-1: Country Code Mismatch
- api-helpers.ts lines 269, 315: fallback `country: 'CA'`
- payment_stripe.py line 558: `if country.lower() != "canada"`
- Fix: Change test fallback to `'Canada'` AND update backend to accept `"ca"`

## MEDIUM-2: totalAmountCents assertion too strict
- stripe-payment.spec.ts line 54: `toBeGreaterThan` should be `toBeGreaterThanOrEqual`
- Tax-exempt + free-shipping products make total == subtotal

## HIGH-3: Dev credentials in version control
- api-helpers.ts lines 15, 26, 39-44
- Firebase API key + email/password for test accounts

## MEDIUM-6: Fixed 5s sleep for stock restoration
- order-cancellation-refund.spec.ts lines 69-74
- Should use polling loop instead

## MEDIUM-8: order-level status update fragile for multi-seller
- order-cancellation-refund.spec.ts lines 41-50
- Backend blocks `update_order_status` for multi-seller orders

## LOW-11: 3DS test trivially passes
- payment-edge-cases.spec.ts line 135: `expect(url).toBeTruthy()` always true
