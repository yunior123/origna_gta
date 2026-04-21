# Origna Ventures Payment Audit

Date: 2026-04-19

## What was tested

### Stripe
- Local Origna Ventures FastAPI backend on `127.0.0.1:8787`
- Real Stripe test secret loaded from local authenticated Stripe CLI via:
  - `origna_gta/orignabase/scripts/stripe-cli-env.sh test`
- Contract signing endpoint:
  - `POST /api/contracts/sign`
- Checkout creation endpoint:
  - `POST /api/payments/create-checkout-session`
- Webhook processing endpoint:
  - `POST /api/stripe/webhook`

### Mailjet
- Remote dev Mailjet credentials pulled from VPS `/opt/orignabase/.env.dev`
- Tested through:
  - `POST /api/email/test`

### PDF / QR artifacts
- One-pager generated:
  - `output/origna_ventures_onepager.pdf`
- Full deck generated:
  - `output/origna_ventures_full_deck.pdf`
- QR targets currently embedded:
  - `https://orignaventures.ca/contract`
  - `https://orignaventures.ca/pay`
  - `https://orignaventures.ca`
  - `https://dev.orignagta.ca`
  - `https://orignaventures.ca/deck`
  - `https://orignaventures.ca/donate`

## Results

### PASS — contract signing
- Contract signing succeeded.
- Signed PDF generated and stored locally.
- PDF download endpoint now returns real `application/pdf` file content.
- Audit fields captured in backend model:
  - typed signature
  - consent checkbox
  - timestamp
  - IP
  - user agent
  - SHA-256 digest

### PASS — Stripe checkout session creation
- Stripe Checkout session creation succeeded with real Stripe test key.
- Verified output included:
  - provider `stripe`
  - status `awaiting_payment`
  - valid `cs_test_...` session ID
  - live checkout URL from `checkout.stripe.com`
- Re-verified on deployed production endpoint `https://api.orignagta.ca/ventures/api/payments/create-checkout-session` after backend redeploy.

### PASS — webhook verification + contract payment status update
- Posted a signed `checkout.session.completed` payload to local webhook.
- Signature verification passed.
- Contract status updated in SQLite from pending to `paid`.

### FAIL — Mailjet credentials
- Remote dev Mailjet credentials returned:
  - `401 Unauthorized`
- Result:
  - Mailjet is not currently usable from the tested credentials set.
- This blocks reliable signed-contract confirmation emails and payment-confirmation emails.

## Audit findings

### 1. Pricing drift existed between business terms and code
Fixed in code during audit:
- `OrignaCode`: `500 CAD`
- `OrignaLaunch`: `1,000 CAD`
- `OrignaTeam`: `1,000+ CAD / month`

Updated in:
- `backend/app.py`
- `lib/main.dart`
- `scripts/generate_presentation_pdfs.py`

### 2. QR payment flow is generic, not invoice-specific
Current QR codes point to generic landing pages like `/pay`.
That is good for brochure/deck discovery, but not enough for a true payable invoice QR.

Recommended production split:
- brochure QR → generic `/pay`
- contract QR → `/contract`
- real payment QR → unique Stripe Checkout URL generated per signed contract

### 3. Venn removed from active payment flow
The active payment flow is now Stripe-only.
All contract payment handoff should create a Stripe Checkout session and redirect there.

### 4. Stripe CLI docs are present, but current best payment path is:
- sign contract
- create Stripe Checkout session
- redirect to Stripe hosted checkout
- receive `checkout.session.completed`
- unlock repo access after verified payment

### 5. PDF output is working
Generated successfully:
- `output/origna_ventures_onepager.pdf`
- `output/origna_ventures_full_deck.pdf`
- Production backend now serves real PDF bytes from `GET /ventures/api/contracts/{id}/pdf` with `content-type: application/pdf` after redeploy.

## Recommended next changes

### High priority
1. Replace invalid Mailjet credentials with working ones.
2. Generate contract-specific payment QR after checkout session creation.
3. Persist checkout URL on contract record.
4. Add repo unlock automation after paid webhook.
5. Keep all public payment UX Stripe-only unless a real second provider is fully implemented.

### Medium priority
1. Add admin page to list signed/pending/paid contracts.
2. Add signed contract + receipt email templates in both EN/FR.
3. Add GitHub org invite flow after payment confirmation.
4. Add explicit refund / pre-unlock cancellation state transitions.

## Files involved
- `backend/app.py`
- `lib/main.dart`
- `scripts/generate_presentation_pdfs.py`
- `output/origna_ventures_onepager.pdf`
- `output/origna_ventures_full_deck.pdf`
