# Origna Ventures Payment Audit

Date: 2026-04-21

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

### 3. Mailjet remains an operational dependency to verify separately

- Mailjet is still relevant for confirmations/notifications.
- Credential validity and delivery behavior should be verified with current production secrets, not stale dev assumptions.

## Recommended next checks

### High priority

1. Re-run live payment verification against all three public service codes.
2. Re-verify webhook handling on the currently deployed production backend.
3. Verify current Mailjet delivery with valid production credentials.

### Medium priority

1. Keep public PDFs and homepage pricing copy regenerated together after any tier change.
2. Keep legacy contract/admin flows documented as internal/backoffice only.
3. Add explicit evidence links/logs when live Stripe or Mailjet passes are re-run.

## Files involved

- `origna_ventures/backend/app.py`
- `origna_ventures/lib/main.dart`
- `origna_ventures/lib/tiers_config.dart`
- `origna_ventures/scripts/generate_presentation_pdfs.py`
- `origna_ventures/web/docs/origna_ventures_onepager.pdf`
- `origna_ventures/web/docs/origna_ventures_full_presentation.pdf`
