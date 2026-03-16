# Stripe Payment Rules — origna_gta

## Money — Always Integer Cents
- Every monetary value in the entire stack is integer cents: `totalAmountCents`, `subtotalCents`, `taxAmountCents`, `shippingCostCents`, `platformFeeTotalCents`.
- Never use `double` or `float` for money anywhere.
- Divide by 100 ONLY at the display/formatting layer.
- Stripe API also uses integer cents — pass values directly without conversion.

## Stripe Checkout Flow
1. Flutter calls OrignaBase `/payments/checkout` with cart items and shipping address.
2. OrignaBase creates a Stripe Checkout Session (server-side) and returns `session_url`.
3. Flutter opens `session_url` in a WebView or redirects to it.
4. Stripe redirects back to `success_url` or `cancel_url` defined in OrignaBase config.
5. `payment_intent.succeeded` webhook confirms the order — do NOT confirm on redirect alone.

## Webhook Rules
- Webhook endpoint: `https://api.dev.orignagta.ca/stripe/webhook` (dev) / `https://api.orignagta.ca/stripe/webhook` (prod).
- Signature must be verified via HMAC (`Stripe-Signature` header) on every incoming webhook.
- Webhook secret is loaded from Secret Manager in deployed mode — NOT from env vars.
- Dev endpoint ID: `we_1T2ESaPPD6r8xGIzV45SJGbm`. Staging: `we_1T5bO3PPD6r8xGIzBmeQRLwK`.
- Process webhooks idempotently: check `webhook_events` collection for duplicate event IDs before processing.
- `webhook_events` timestamp field is `timestamp` (not `createdAt`).

## Idempotency
- All Stripe API calls from OrignaBase must include `Idempotency-Key` headers.
- Key format: `<order_id>-<action>` (e.g., `ord_01HXZ...-refund`).
- Duplicate webhook events must be silently ignored (already processed check).

## Platform Fee
- Rate: `platformFeeTotalCents / subtotalCents` (numerator / denominator — NOT totalAmountCents).
- Collected via Stripe Connect `application_fee_amount`.
- Platform fee is non-refundable on buyer refunds.

## Stripe Connect (Seller Payouts)
- Every seller has a Stripe Connect account linked to their `seller_profiles` record.
- Payouts triggered by OrignaBase after order reaches `delivered` state (or configurable delay).
- Seller receives `subtotalCents - platformFeeTotalCents` (shipping is passed through separately).
- Never initiate a payout before order is confirmed delivered.

## Metadata Keys
- Session created with `metadata["order_id"]` (snake_case — `StripeConstants.METADATA_ORDER_ID`).
- Webhook handlers MUST read `metadata.get(StripeConstants.METADATA_ORDER_ID)` — NOT `Fields.ORDER_ID`.
- Mixing these two keys is a known source of silent failures.

## Webhook Memory (OOM Fix)
- `stripe_webhook` Cloud Function: `WEBHOOK_OPTIONS` must set `memory: options.MemoryOption.MB_512`.
- Default 256 MiB causes OOM crashes under load.

## Forbidden
- Never call Stripe API directly from Flutter — all Stripe calls go through OrignaBase.
- Never store Stripe secret keys in Flutter code or `dart-define` variables.
- Never confirm an order based solely on a redirect URL — always wait for webhook.
- Never skip webhook signature verification even in development.
- Never pass `double` amounts to Stripe — always integer cents.

## Shipping Address
- Always include `shipping_address_collection` in Checkout Session creation.
- If Stripe returns empty `shipping_details`, skip address comparison (known Stripe edge case).
- Address mismatch check: compare Stripe shipping address vs. OrignaBase order address.

## Test Cards (Dev Only)
- Success: `4242 4242 4242 4242`
- Requires auth: `4000 0025 0000 3155`
- Decline: `4000 0000 0000 9995`
- Never use real cards in dev/staging environments.
