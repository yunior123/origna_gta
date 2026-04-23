@~/CLAUDE.md

# CORE.md — OrignaGTA Workboard

Single source of truth for active work.

Rules:
- Only mark `[x]` after real verification.
- Move completed one-off items to `STATE.md`; do not leave stale history here.
- Keep items updated in place; do not duplicate the same task in multiple sections.
- Save command output to `/tmp/...` for long runs.
- Prefer focused, reproducible verification before broad sweeps.

## Definition of done
- [ ] Code/config updated if needed.
- [ ] Relevant tests or live checks passed.
- [ ] Regressions covered when the bug is repeatable/high-value.
- [ ] `STATE.md` updated with evidence and impact.
- [ ] Item removed from this file once truly complete.

## P0 — Close current verified-but-open delivery blockers

### 1) Cuba parity closeout
- [ ] Update the store to support Cuba in every aspect similarly to Canada.
  - Current verified state: frontend country/province/address validation, Cuba maritime shipping logic, zero-tax handling, backend Canada/Cuba province validation, and the dedicated Cuba address widget flow are present and re-verified.
  - Verified evidence already on record:
    - `cd origna_gta && flutter test test/unit/schema_constants_test.dart test/unit/utils_comprehensive_test.dart test/unit/utils_coverage_boost_test.dart`
    - `cd origna_gta && flutter test test/widget/cuba_address_form_test.dart test/unit/address_viewmodel_test.dart`
    - `cd origna_gta && flutter analyze --no-fatal-infos lib/features/profile/address_viewmodel.dart lib/screens/editaddress_screen.dart test/widget/cuba_address_form_test.dart test/unit/address_viewmodel_test.dart`
    - `cd orignabase && cargo test -p ob-handlers test_canada_and_cuba_provinces_are_valid -- --nocapture`
  - Still required before close:
    - full end-to-end Cuba checkout/live UX audit
    - proof that real Cuba-specific address, shipping, tax, and checkout UX all behave correctly end-to-end

### 2) Spanish audit closeout
- [ ] Audit Spanish translations across the app.
- Current verified state: runtime Spanish support exists in OrignaGTA and OrignaVentures; OrignaGTA test/preview scaffolds were upgraded to include Spanish; address-flow hardcoded English errors were replaced with translated `address.*` keys in `en/fr/es`; the highest-signal `auth`, `subscription`, `seller`, and shopper-facing `checkout` / `product` copy received a direct Spanish pass.
- Latest progress on 2026-04-22: **742 strings translated** (2307 → 1565 identical en→es values remaining)
- Verified evidence already on record:
  - `supportedLocales` includes `es`
  - OrignaVentures supports `LocaleMode.es` and `loc.tr(..., ..., es)`
  - test/preview helpers updated in `test_utils.dart`, `main_test.dart`, `preview_helpers.dart`, `origna_app_test.dart`, `origna_app_routes_test.dart`, and `chat_screen_test.dart`
  - `origna_gta/lang_selector_gaps.txt` now records the latest untranslated-value counts by module:
    - `admin`: `213`
    - `checkout`: `159`
    - `product`: `140`
    - `specs`: `131`
    - `orders`: `114`
    - `supplier`: `104`
- Still required before close:
  - finish the remaining long-tail English surfaces concentrated in `admin.*`, `checkout.*`, `product.*`, `specs.*`, `orders.*`, `supplier.*`

### 3) Payment system closeout
- [ ] Test all payment-related views and features in OrignaVentures and OrignaGTA, including backend flows.
  - Current verified state:
    - Ventures checkout-session idempotency regression fixed and redeployed
    - webhook-security `500` regression fixed and redeployed
    - `origna_ventures/backend/tests/test_payments_api.py` passes at `19 passed`
    - live no-email checkout probes for `origna_code`, `origna_launch`, `origna_team` return `200`
    - `origna-ventures-tax-live.spec.ts` is green
    - webhook-security block in `origna-ventures-live.spec.ts` is green again
    - `origna-ventures-mobile-pricing-live.spec.ts` passes (`2/0`)
    - receipt-email backend path now generates PDF attachments in tests
  - Still required before close:
    - full repo-wide payment audit across OrignaGTA + OrignaVentures
    - close the flaky mixed mobile live suite behavior
    - complete fresh end-to-end payment verification for the remaining surfaces

### 4) Receipt/invoice closeout
- [ ] Send invoice receipt to clients after buying tiers, attached PDF included similar to OrignaGTA; email should be in English or French depending on user language or both.
- Current verified state:
  - Ventures backend generates a PDF receipt attachment for tier purchase receipt emails
  - attachment is included only on the client receipt email, not on the internal support copy
  - backend tests cover the behavior
  - backend was redeployed live
  - PDF now includes business legal name, business number (BN), invoice number (INV-{session_id}), developer count for OrignaTeam, full EN/FR/ES locale labels
  - `generate_receipt_pdf()` enhanced with `developer_count` param, business details, Spanish labels
- Verified evidence already on record:
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed`
  - `test_generate_receipt_pdf_contains_business_details`, `test_generate_receipt_pdf_french_labels`, `test_generate_receipt_pdf_spanish_labels` all pass
  - `cd origna_ventures && ./deploy.sh --backend-only`
- Still required before close:
  - live paid purchase proving real inbox delivery with the attached PDF
  - final locale decision/proof for English/French behavior

### 5) Ventures backend concurrency/reliability closeout
- [ ] Make sure backend supports concurrency for OrignaVentures when sending emails and paying. Find other gaps apart from concurrency to make sure backend is solid.
- Current verified state:
  - payment webhook commits DB state before dispatching emails
  - contact-form support/confirmation emails use the shared concurrent email-job helper
  - duplicate webhooks are idempotent
  - real Stripe CLI signed deliveries for `checkout.session.expired` and `invoice.payment_failed` returned `200` locally
  - email queue with SQLite persistence: `email_queue` table, `enqueue_email_job()`, `enqueue_email_jobs()`, retry (3 attempts), dead letter storage
  - `_email_queue_sync_mode` flag for test determinism
  - webhook price validation: cross-checks `amount_subtotal` against expected catalog price × quantity
  - subscription lifecycle email notifications (deleted, payment_failed, updated) with EN/FR/ES locales
  - `OperationalError` handling returns 503 on DB lock
  - SQLite concurrency fixes: `BEGIN IMMEDIATE` locking, connection leak fix, TOCTOU race fixes, webhook email enqueue isolation
  - all backend magic strings replaced with module-level constants
- Verified evidence already on record:
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed` (12 new regression tests)
- Still required before close:
  - broader SQLite write/load/concurrency stress testing under real concurrent load
  - remaining Stripe-doc alignment across repo

### 6) Payment hardening follow-up audits
- [ ] Audit payment system in entire repo as per latest Stripe docs.
- [ ] Audit magic strings in app; replace high-risk runtime strings with shared constants/enums where needed.
- Current verified state:
  - stale Ventures Stripe/tier docs were rewritten to match the live public Checkout Session flow and active tier catalog
  - Ventures backend magic strings fully remediated: all service codes, payment statuses, subscription statuses, webhook event types, and email queue statuses now use module-level constants
- Verified evidence already on record:
  - `origna_ventures/docs/TIER_REFACTOR.md`
  - `origna_ventures/docs/stripe_research.md`
  - `cd origna_ventures/backend && source .venv/bin/activate && pytest tests/test_payments_api.py` → `31 passed`
- Still required:
  - OrignaGTA Flutter frontend magic string audit (schema_constants.dart coverage gaps)
  - full repo-wide payment audit across OrignaGTA + OrignaVentures

## P1 — Product, design, and release work

### Design / UX
- [ ] Make the splash theme and OrignaVentures theme feel aligned; push toward a more expensive investor-ready direction, then re-test payment features after the pass.
- [ ] Continue OrignaVentures visual polish after the 2026-04-21 hero/proof-panel pass if more improvement is still needed.

### Content / assets
- [ ] Use realistic test seeded products from AliExpress, upload images to Cloudflare, and research Cloudflare best practices first for `dev.orignagta.ca`.
- [ ] Add the first products to production from `/Users/yuniorrodriguezosorio/Downloads/Quote` and `/Users/yuniorrodriguezosorio/Downloads/Quote for split phase AC120V 10KW Hybrid Solar System  --2026.pdf`.
  - Advanced state: extracted/improved solar images already in repo were wired into the live solar product via production static asset URLs; broader production catalog import is still pending.
- [x] Insert the solar module product into production with full home delivery + installation and make sure it is sold by Origna Ventures using the company Stripe config.
  - Verified on 2026-04-22: `e2e/specs/phase4-product-flows/prod-solar-product-live.spec.ts` passes (2/0), confirming live product at `https://orignagta.ca/product/207123c5-a5ee-4a8e-8f3b-434664110bc0` with expected title, description, seller (`OrignaVentures`), price (13,000 CAD), and solar assets. Remaining manual step: full order/payment verification on the company Stripe path.

### Release / delivery
- [ ] Deploy the latest version of OrignaGTA and OrignaVentures.
  - Advanced state: OrignaGTA production was redeployed again as release `20260422113324`; latest OrignaVentures frontend/docs were already redeployed earlier; a final both-apps pass is still pending.
- [ ] Commit and push all changes to GitHub.
- [ ] Build the iOS app.

## P2 — Manual QA / human-required checkpoints
- [ ] Final production OrignaGTA live checkout/payment verification for `https://orignagta.ca/product/207123c5-a5ee-4a8e-8f3b-434664110bc0`.
  - Automated coverage already verifies description, seller, price, assets, and product-page fetch.
  - Remaining manual step: approved live buyer/payment path because production login and checkout are Turnstile-gated.

## P3 — Growth / business backlog
- [ ] Add `orignaventures.ca` to Yelp.
- [ ] Launch campaign to find clients for solar panels/modules.
- [ ] Advertising campaign to sell our services.

## Notes
- Completed one-off items live in `STATE.md`.
- Historical proofs should not be re-added here once moved to `STATE.md`.
