# Stripe research notes

Date: 2026-04-22

This file records the current Origna Ventures Stripe direction. Earlier notes that centered the public flow on donation/brochure Payment Links or post-signature contract checkout are historical and no longer describe the live public tiers flow.

## Current production-aligned model

- Public service cards create Stripe Checkout Sessions from the Ventures backend.
- The active public catalog is:
  - `origna_code`
  - `origna_launch`
  - `origna_team`
- Checkout metadata is service-oriented and can include server-validated extras such as `developer_count` for `origna_team`.
- Tax handling uses Stripe-hosted `automatic_tax` plus `tax_id_collection`.
- Fulfillment and email side effects happen after verified webhook events.

## Why Checkout Sessions, not static Payment Links

- The live flow needs request-time metadata such as `service_code`, buyer email, locale context, and bounded `developer_count`.
- The backend must remain authoritative over pricing and quantity so client-side source access cannot manipulate payable amounts.
- The webhook layer needs a stable path for idempotency, receipt generation, support notifications, and future fulfillment logic.

## Webhook guidance in use

- verify signed raw webhook payloads
- deduplicate repeated deliveries
- return `2xx` quickly and avoid blocking the webhook response on email delivery
- keep fulfillment and receipts keyed off successful Stripe events

## Official Stripe docs reviewed

- `https://docs.stripe.com/api/checkout/sessions/create`
- `https://docs.stripe.com/webhooks/test`
- `https://docs.stripe.com/error-low-level`
- `https://docs.stripe.com/keys`

## Local repo evidence

- `origna_ventures/backend/app.py`
- `origna_ventures/docs/payment_audit.md`
- `STATE.md`
