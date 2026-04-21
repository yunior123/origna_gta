# Stripe research notes

Date: 2026-04-19

## Sources checked
- `https://docs.stripe.com/payment-links`
- `https://docs.stripe.com/payments/checkout`
- local repo guide: `origna_gta/docs/stripe-cli-guide.md`

## Key findings

### Payment Links
Stripe documents Payment Links as a shareable hosted payment surface that can be sent on websites, email, social media, and QR-driven flows.

Relevant extracted points:
- "Accept payments with shareable links"
- Stripe-hosted payment page
- QR-compatible sharing/use cases are mentioned in Stripe docs navigation and invoice/payment sharing contexts

Best use for Origna Ventures:
- static brochure/payment QR
- sponsor/donation QR
- generic payment collection pages

### Checkout
Stripe Checkout is Stripe's hosted checkout flow for collecting payment with a better per-transaction context than a static public payment link.

Best use for Origna Ventures:
- contract-specific payment after signing
- attach metadata like `contract_id`, `service_code`, and `client_email`
- fulfill/unlock access after webhook confirmation

### Recommended production split
- brochure QR / donation QR / public sponsor QR → Stripe Payment Links
- signed contract payment → Stripe Checkout Session
- fulfillment / repo unlock → Stripe webhook (`checkout.session.completed`)

## Local project evidence
- local Stripe test secret successfully created Checkout sessions in Origna Ventures backend
- local signed webhook test successfully updated contract status to `paid`
- local Mailjet test still failed with `401 Unauthorized` using current dev credentials pulled from VPS config
