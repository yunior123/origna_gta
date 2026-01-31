#+#+#+#+ origna_gta (Flutter app)

Canada-only marketplace app (Web, Android, iOS) using Firebase + Stripe Connect Express.

## Architecture (MVVM)
- UI → ViewModels → Repositories → Firebase/Stripe services
- No business logic in widgets
- Idempotent payments + defensive validation

## App flow diagram
```mermaid
sequenceDiagram
	participant U as User
	participant A as App
	participant F as Firebase Functions
	participant S as Stripe
	participant DB as Firestore

	U->>A: Checkout
	A->>F: create_checkout_session (idempotencyKey)
	F->>DB: Validate stock, reserve, create order
	F->>S: Create Checkout Session (manual capture, tax)
	S-->>A: Hosted checkout URL
	S-->>F: Webhook events (session completed, PI status)
	F->>DB: Update order totals/taxes/status
	A->>F: confirm_order_receipt (buyer)
	F->>S: Capture payment
	S-->>F: transfer events
```

## Setup
1. Flutter: `flutter pub get`
2. Run app: `flutter run`
3. Tests: `../scripts/run_all_tests.sh`

## Stripe Connect (direct charges)
- Manual capture authorization
- Capture after shipment/receipt confirmation
- Platform fee: 2.5%

## Stripe test cards
- 4242 4242 4242 4242 (success)
- 4000 0000 0000 9995 (insufficient funds)
- 4000 0000 0000 0002 (generic decline)
- 4000 0025 0000 3155 (3DS required)

Use any future expiry, any CVC, any postal code.

## Future hardening
- Validate multi-seller shipping math with mixed delivery options.
- Add full checkout E2E tests.
- Expand threat-model tests for cart/checkout abuse.




