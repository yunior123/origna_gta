# Stripe CLI Guide — OrignaGTA

## Binary Location

```bash
/opt/homebrew/bin/stripe
```

## Authentication

```bash
# Login (opens browser for OAuth)
/opt/homebrew/bin/stripe login

# Verify auth
/opt/homebrew/bin/stripe config --list
```

Current account: `acct_1StdiwPPD6r8xGIz` (1001475263 ONTARIO CORPORATION).
Test mode key expires: 2026-06-12. Re-login before then.

## Webhook Endpoints

### Registered Endpoints

| ID | Env | URL | Status | Mode |
|----|-----|-----|--------|------|
| `we_1TBt7uPPD6r8xGIz9VzZXiXP` | Dev | `https://api.dev.orignagta.ca/api/webhooks/stripe` | enabled | test |
| `we_1TBt8BPPD6r8xGIzSpeuwv4P` | Staging | `https://api.staging.orignagta.ca/api/webhooks/stripe` | enabled | test |
| `we_1TBCwLPPD6r8xGIzGibCx74G` | Prod | `https://api.orignagta.ca/api/webhooks/stripe` | enabled | **live** |
| `we_1SuPX4PPD6r8xGIzXKV0MOKr` | Legacy | `cloudfunctions.net/stripe_webhook` | **disabled** | live |

### Events Registered per Endpoint

**Dev & Staging** (explicit list):
- `checkout.session.completed`
- `checkout.session.async_payment_succeeded`
- `checkout.session.async_payment_failed`
- `checkout.session.expired`
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `payment_intent.canceled`
- `charge.refunded`
- `charge.dispute.created`
- `account.updated`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`

**Prod** (wildcard `*` — receives ALL events).

## Listening for Webhooks Locally

Forward Stripe events to your local OrignaBase instance:

```bash
# Forward to local dev server (port 8080)
/opt/homebrew/bin/stripe listen --forward-to http://localhost:8080/api/webhooks/stripe

# With specific events only
/opt/homebrew/bin/stripe listen \
  --forward-to http://localhost:8080/api/webhooks/stripe \
  --events payment_intent.succeeded,charge.refunded,checkout.session.completed

# The CLI will print a webhook signing secret (STRIPE_WEBHOOK_SECRET_REDACTED).
# Set this in your local .env: OB_SECRETS__STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED
```

## Triggering Test Events

```bash
# Trigger a payment_intent.succeeded event
/opt/homebrew/bin/stripe trigger payment_intent.succeeded

# Trigger checkout session completed
/opt/homebrew/bin/stripe trigger checkout.session.completed

# Trigger charge refund
/opt/homebrew/bin/stripe trigger charge.refunded

# Trigger subscription lifecycle
/opt/homebrew/bin/stripe trigger customer.subscription.created
/opt/homebrew/bin/stripe trigger customer.subscription.updated
/opt/homebrew/bin/stripe trigger customer.subscription.deleted

# Trigger payment failure
/opt/homebrew/bin/stripe trigger payment_intent.payment_failed

# Trigger dispute
/opt/homebrew/bin/stripe trigger charge.dispute.created
```

Note: `stripe trigger` sends events to ALL enabled webhook endpoints. There is no `--webhook-endpoint` flag.

## Checking Webhook Delivery Logs

```bash
# List recent events
/opt/homebrew/bin/stripe events list --limit 10

# Filter by event type
/opt/homebrew/bin/stripe events list --type payment_intent.succeeded --limit 5

# Get specific event details
/opt/homebrew/bin/stripe events retrieve evt_XXXXXXXXXXXX

# List webhook endpoints and their status
/opt/homebrew/bin/stripe webhook_endpoints list
/opt/homebrew/bin/stripe webhook_endpoints list --live  # prod endpoints
```

## Tailing Webhook Events (Real-time)

```bash
# Listen and print events in real time (no forwarding)
/opt/homebrew/bin/stripe listen --print-json

# Listen with forwarding + JSON output
/opt/homebrew/bin/stripe listen \
  --forward-to http://localhost:8080/api/webhooks/stripe \
  --print-json
```

## Checking VPS Logs for Webhook Receipt

```bash
# Dev container
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16 \
  "docker logs orignabase-orignabase-dev-1 --tail 50 2>&1 | grep -i webhook"

# Staging container
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16 \
  "docker logs orignabase-orignabase-staging-1 --tail 50 2>&1 | grep -i webhook"

# Prod container
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16 \
  "docker logs orignabase-orignabase-prod-1 --tail 50 2>&1 | grep -i webhook"
```

## Common Event Types for OrignaGTA

| Event | Purpose | OrignaBase Handler |
|-------|---------|-------------------|
| `payment_intent.succeeded` | Order payment confirmed | Confirms order, decrements stock, marks coupon used |
| `payment_intent.payment_failed` | Payment failed | Cancels order, releases coupon |
| `payment_intent.canceled` | Payment canceled | Cancels order |
| `charge.succeeded` | Charge completed | Logs charge |
| `charge.failed` | Charge failed | Logs failure |
| `charge.refunded` | Refund processed | Updates order, restores stock |
| `customer.subscription.created` | New subscription | Creates subscription record |
| `customer.subscription.updated` | Subscription changed | Updates subscription record |
| `customer.subscription.deleted` | Subscription canceled | Marks subscription canceled |
| `invoice.paid` | Invoice paid (subscriptions) | Updates subscription billing |
| `invoice.payment_failed` | Invoice payment failed | Flags subscription payment issue |
| `checkout.session.completed` | Checkout completed | **NOT HANDLED (GAP)** |
| `checkout.session.expired` | Session expired | **NOT HANDLED (GAP)** |
| `charge.dispute.created` | Dispute opened | **NOT HANDLED (GAP)** |
| `account.updated` | Connect account changed | **NOT HANDLED (GAP)** |

## Webhook Secrets

Secrets are configured on the VPS in `/opt/orignabase/.env.{dev,staging,prod}` as `OB_SECRETS__STRIPE_WEBHOOK_SECRET`.

| Env | Endpoint ID | Secret prefix |
|-----|------------|---------------|
| Dev | `we_1TBt7uPPD6r8xGIz9VzZXiXP` | `STRIPE_WEBHOOK_SECRET_REDACTED...` |
| Staging | `we_1TBt8BPPD6r8xGIzSpeuwv4P` | `STRIPE_WEBHOOK_SECRET_REDACTED...` |
| Prod | `we_1TBCwLPPD6r8xGIzGibCx74G` | `STRIPE_WEBHOOK_SECRET_REDACTED...` |

## Troubleshooting

1. **Webhook returns 401/403**: Check `OB_SECRETS__STRIPE_WEBHOOK_SECRET` matches the endpoint's signing secret
2. **Events not arriving**: Verify endpoint status is `enabled` (`stripe webhook_endpoints list`)
3. **Duplicate processing**: OrignaBase stores event IDs in `webhook_events` collection for dedup
4. **Signature verification fails**: Clock skew > 300s will reject. Check VPS time: `date -u`
5. **Local testing**: Always use `stripe listen` — never bypass signature verification
