# OrignaGTA Monorepo

This repo contains:
- Flutter app: origna_gta
- Firebase Functions backend: functions

## Architecture overview
- MVVM in Flutter
- Functions own payment/shipping validation
- Idempotent payment and webhook processing

## End-to-end flow (payments)
```mermaid
sequenceDiagram
  participant U as User
  participant App as Flutter App
  participant Fn as Functions
  participant Stripe as Stripe
  participant DB as Firestore

  U->>App: Start checkout
  App->>Fn: create_checkout_session (idempotencyKey)
  Fn->>DB: Validate stock, reserve, create order
  Fn->>Stripe: Create Checkout Session (manual capture, tax)
  Stripe-->>App: Hosted checkout URL
  Stripe-->>Fn: Webhooks (session completed / PI status)
  Fn->>DB: Update order totals, taxes, status
  App->>Fn: confirm_order_receipt
  Fn->>Stripe: Capture payment
```

## Quick commands
- Run all tests: scripts/run_all_tests.sh
- Flutter analyze: (cd origna_gta) flutter analyze
- Flutter tests: (cd origna_gta) flutter test
- Functions tests: (cd functions) pytest

## Docs
- App README: origna_gta/README.md
- Functions README: functions/Readme.md

## Environments
- Canada-only delivery enforced in Functions.
- Stripe Connect Express direct charges, manual capture.
