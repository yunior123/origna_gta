# Origna Ventures Services

Last updated: 2026-04-22

This file reflects the current public tier model.

## Active tiers

- `OrignaCode`
  - `500 CAD` one-time
  - source-code purchase / starter delivery path

- `OrignaLaunch`
  - `3,000 CAD` one-time
  - launch package / implementation delivery path

- `OrignaTeam`
  - `1,000 CAD` per developer, per month
  - buyer-selectable `1..20` developers
  - server-authoritative pricing via the backend service catalog

## Notes

- Legacy `Essential / Professional / Enterprise` wording is obsolete and should not be used for current product, payment, or deck work.
- Checkout is created through Stripe Checkout Sessions, not static tier-specific Payment Links.
- Tax calculation is Stripe-hosted via `automatic_tax` and `tax_id_collection`, not a hardcoded HST line item.

## Source of truth

- `origna_ventures/lib/tiers_config.dart`
- `origna_ventures/backend/app.py`
- `origna_ventures/docs/payment_audit.md`
