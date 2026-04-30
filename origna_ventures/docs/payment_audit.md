# Origna Ventures Payment Audit

Date: 2026-04-22

## Current public payment architecture

- Public website: `https://orignaventures.ca`
- Public API: `https://api.orignaventures.ca`
- Payment model:
  - `OrignaCode` -> one-time Stripe Checkout
  - `OrignaLaunch` -> one-time Stripe Checkout
  - `OrignaTeam` -> monthly Stripe subscription Checkout
- Public UX:
  - homepage pricing cards are the primary payment entry point
  - cards post directly to `/api/payments/create-checkout-session`
  - public users are not routed through legacy `/pay`, `/contract`, `/deck`, or donation pages

## What is verified

### Stripe checkout

- Backend service codes are:
  - `origna_code`
  - `origna_launch`
  - `origna_team`
- Backend service catalog pricing is:
  - `OrignaCode`: `500 CAD`
  - `OrignaLaunch`: `3,000 CAD`
  - `OrignaTeam`: `1,000 CAD / month`
- The backend now uses:
  - one-time checkout payloads for `origna_code` and `origna_launch`
  - recurring subscription payloads for `origna_team`

### Public UX

- Homepage tier cards are the intended public checkout path.
- Current naming is:
  - `OrignaCode`
  - `OrignaLaunch`
  - `OrignaTeam`
- No public `service 0/1/2` naming should remain in active user-facing flows.

### PDFs

- Public one-pager:
  - `https://orignaventures.ca/docs/origna_ventures_onepager.pdf`
- Public full presentation:
  - `https://orignaventures.ca/docs/origna_ventures_full_presentation.pdf`
- Public PDF pricing/copy was refreshed again on 2026-04-21 to match:
  - `500 CAD`
  - `3,000 CAD`
  - `1,000 CAD / month`
  - `8 GB RAM + 80 GB disk`

## Historical / legacy notes

- Contract signing still exists in backend/history terms, but it is not the intended public purchase flow anymore.
- Public payment routing should be treated as pricing-card -> Stripe Checkout.
- Manual repository access remains policy:
  - no automated GitHub collaborator invite flow
  - no automatic source-code unlock by email

## Findings

### 1. Pricing drift existed and was corrected

Corrected source-of-truth locations include:

- `origna_ventures/lib/tiers_config.dart`
- `origna_ventures/lib/main.dart`
- `origna_ventures/backend/app.py`
- `origna_ventures/scripts/generate_presentation_pdfs.py`
- related audit docs

### 2. Public payment docs had drifted toward removed routes

Outdated references to `/pay`, `/contract`, `/deck`, and donation-era flows were historical, not current public architecture.

Current public expectation:

- pricing card -> checkout session creation
- redirect to Stripe-hosted checkout
- webhook-driven fulfillment/state update

### 3. Postal remains an operational dependency to verify separately

- Postal is the active self-hosted email API for confirmations/notifications.
- Current expected surfaces:
  - contact-form confirmation to the visitor
  - contact-form notification to `support@orignaventures.ca`
  - Stripe checkout/payment notification paths
  - admin `/api/email/test` smoke endpoint
- Credential validity and delivery behavior should be verified with current production secrets, not stale dev assumptions.

### 4. Self-hosted API dependencies to keep in Ventures plans

| API | Purpose | Production expectation | Verification |
|-----|---------|------------------------|--------------|
| Postal email | Contact confirmations, admin notices, payment/service notifications | Self-hosted Postal only; no Firebase/SendGrid/Mailgun fallback | `origna-ventures-contact-live.spec.ts` and admin `/api/email/test` |
| Meilisearch search | OrignaGTA product discovery proof used by the Ventures sales/deck story | Search is served by self-hosted OrignaBase/Meilisearch, not hosted Algolia/Elastic Cloud | `selfhosted-integrations.spec.ts` product search assertions |
| GlitchTip error logging | Error visibility for Flutter/OrignaBase support IDs and structured `error_events` | Self-hosted GlitchTip DSN from OrignaBase public config | `selfhosted-integrations.spec.ts` GlitchTip DSN and error-event assertions |

### 5. Stripe-docs alignment verified on 2026-04-22

Official Stripe docs checked during this pass:

- Checkout Session create API:
  - https://docs.stripe.com/api/checkout/sessions/create
- Webhook testing and best practices:
  - https://docs.stripe.com/webhooks/test
- Low-level error handling / idempotency guidance:
  - https://docs.stripe.com/error-low-level
- API keys and separation of secrets:
  - https://docs.stripe.com/keys

Current alignment after the 2026-04-22 fixes:

- Ventures checkout uses unique per-request Stripe idempotency keys.
- Ventures webhook verifies the signed raw request body and enforces Stripe's timestamp recency window.
- Ventures checkout now uses Stripe-hosted `automatic_tax` and `tax_id_collection` instead of a hardcoded HST line item.
- Ventures webhook now commits DB state before email work and no longer waits for email delivery before returning the webhook response.
- Ventures buyer receipt email now includes a PDF attachment in backend-tested flows.
- Ventures `OrignaTeam` quantity/pricing is server-authoritative via validated `developer_count` and fixed server-side unit pricing.

Repo-wide audit notes:

- OrignaGTA / OrignaBase checkout already uses server-authoritative subtotal, shipping, tax, and idempotency-key handling in Rust.
- OrignaGTA tax is still calculated server-side from validated address/shipping context rather than delegated to Stripe Tax; that is a deliberate architecture choice, not an unverified client-side calculation.
- The remaining payment gaps are operational/live-surface gaps, not core Stripe-signature or price-tampering bugs:
  - the giant legacy Ventures mobile live suite remains flaky under repeated browser launches
  - full production buyer-charge proof for OrignaGTA remains manual due Turnstile / real-payment constraints
  - inbox-level proof for the attached Ventures PDF receipt is still not captured from a real completed paid flow

## Recommended next checks

### High priority

1. Re-run live payment verification against all three public service codes.
2. Re-verify webhook handling on the currently deployed production backend.
3. Verify current Postal delivery with valid production credentials and literal inbox receipt evidence.
4. Re-run the focused mobile Stripe redirect cases after deploy to confirm the mixed-run `PW13` timeout remains only a flake.

### Medium priority

1. Keep public PDFs and homepage pricing copy regenerated together after any tier change.
2. Keep legacy contract/admin flows documented as internal/backoffice only.
3. Add explicit evidence links/logs when live Stripe, Postal, Meilisearch, or GlitchTip passes are re-run.

## Files involved

- `origna_ventures/backend/app.py`
- `origna_ventures/lib/main.dart`
- `origna_ventures/lib/tiers_config.dart`
- `origna_ventures/scripts/generate_presentation_pdfs.py`
- `origna_ventures/web/docs/origna_ventures_onepager.pdf`
- `origna_ventures/web/docs/origna_ventures_full_presentation.pdf`
