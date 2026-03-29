# OrignaGTA Webhook Documentation

Stripe webhooks power order confirmation, payment capture, and refund processing in OrignaGTA. This document explains how webhooks work, how to verify them, and what events are handled.

---

## Overview

**Webhook Endpoint**: `POST https://api.orignagta.ca/stripe/webhook`

**Dev Endpoint**: `https://api.dev.orignagta.ca/stripe/webhook`

Stripe sends webhook events to this endpoint whenever:
- A payment is successful
- A payment fails
- A refund is issued
- A customer is created/updated

The backend verifies the webhook signature (HMAC-SHA256) and processes the event idempotently.

---

## Webhook Signature Verification

Every incoming webhook includes a `Stripe-Signature` header:

```
Stripe-Signature: t=1614556800,v1=<signature>,v0=<signature>
```

### Verification Process

The OrignaBase backend verifies using HMAC-SHA256:

1. **Extract timestamp (`t`) and signature (`v1`) from header**
2. **Reconstruct signed content**:
   ```
   signed_content = "{timestamp}.{request_body}"
   ```
3. **Compute HMAC**:
   ```
   computed_signature = HMAC-SHA256(webhook_secret, signed_content)
   ```
4. **Compare** `computed_signature` with provided signature (constant-time)
5. **Verify timestamp** is within 5 minutes (prevent replay attacks)

### Implementation (Rust pseudocode)

```rust
use hmac::{Hmac, Mac};
use sha2::Sha256;

fn verify_stripe_webhook(
    stripe_signature: &str,
    request_body: &str,
    webhook_secret: &str,
) -> Result<()> {
    // Parse header: "t=timestamp,v1=signature"
    let (timestamp, signature) = parse_stripe_signature(stripe_signature)?;
    
    // Verify timestamp is recent
    let now = chrono::Utc::now().timestamp();
    if now - timestamp > 300 {
        return Err("Signature too old (>5 min)");
    }
    
    // Reconstruct signed content
    let signed_content = format!("{}.{}", timestamp, request_body);
    
    // Compute HMAC
    let mut mac = Hmac::<Sha256>::new_from_slice(webhook_secret.as_bytes())?;
    mac.update(signed_content.as_bytes());
    let computed = hex::encode(mac.finalize().into_bytes());
    
    // Constant-time comparison
    if !constant_time_eq(computed, signature) {
        return Err("Invalid signature");
    }
    
    Ok(())
}
```

---

## Webhook Secrets

| Environment | Webhook ID | Endpoint | Secret |
|---|---|---|---|
| **Dev** | `we_1TBt7uPPD6r8xGIz9VzZXiXP` | https://api.dev.orignagta.ca/stripe/webhook | Stored in `/opt/orignabase/.env.dev` |
| **Staging** | `we_1TBt8BPPD6r8xGIzSpeuwv4P` | https://api.staging.orignagta.ca/stripe/webhook | Stored in `/opt/orignabase/.env.staging` |
| **Production** | `we_1TBXXXXPPD6r8xGIzXXXXXXX` | https://api.orignagta.ca/stripe/webhook | Loaded from Secret Manager at runtime |

**Never commit webhook secrets to Git.**

---

## Event Types

OrignaBase handles the following Stripe event types:

### 1. payment_intent.succeeded
A payment has been successfully captured.

**When it fires**: After `charge.succeeded` completes (Stripe best practice).

**Payload**:
```json
{
  "id": "evt_abc123...",
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_abc123xyz",
      "amount": 15750,  // in cents
      "currency": "cad",
      "status": "succeeded",
      "client_secret": "REDACTED_SECRET",
      "metadata": {
        "order_id": "orders:ord_abc123",
        "buyer_id": "users:buyer_xyz"
      },
      "charges": {
        "data": [
          {
            "id": "ch_abc123xyz",
            "amount": 15750,
            "status": "succeeded"
          }
        ]
      }
    }
  },
  "created": 1614556800
}
```

**Actions**:
1. Check if webhook already processed (idempotency via `evt_abc123...`)
2. Update order status: `pending` → `confirmed`
3. Decrement product stock (atomic PostgreSQL transaction)
4. Send confirmation email to buyer
5. Send "new order" alert to seller
6. Record webhook event in `webhook_events` collection

**Idempotency**: If called twice with same `event.id`, skip processing (already recorded).

---

### 2. payment_intent.payment_failed
A payment authorization failed.

**Payload**:
```json
{
  "id": "evt_def456...",
  "type": "payment_intent.payment_failed",
  "data": {
    "object": {
      "id": "pi_def456xyz",
      "status": "requires_payment_method",
      "last_payment_error": {
        "code": "card_declined",
        "message": "Your card was declined.",
        "type": "card_error"
      },
      "metadata": {
        "order_id": "orders:ord_def456",
        "buyer_id": "users:buyer_xyz"
      }
    }
  }
}
```

**Actions**:
1. Update order status: `pending` → `cancelled`
2. Restore cart items to stock
3. Send "payment failed" email to buyer with retry link
4. Log failure reason in order record

---

### 3. payment_intent.canceled
A payment was explicitly cancelled (e.g., checkout expired or buyer cancelled manually).

**Payload**:
```json
{
  "id": "evt_ghi789...",
  "type": "payment_intent.canceled",
  "data": {
    "object": {
      "id": "pi_ghi789xyz",
      "status": "canceled",
      "cancellation_reason": "requested_by_customer",
      "metadata": {
        "order_id": "orders:ord_ghi789"
      }
    }
  }
}
```

**Actions**:
1. Update order status: `pending` → `cancelled`
2. Restore stock
3. Send cancellation email

---

### 4. charge.succeeded
A charge completed successfully.

**Payload**:
```json
{
  "id": "evt_jkl012...",
  "type": "charge.succeeded",
  "data": {
    "object": {
      "id": "ch_jkl012xyz",
      "amount": 15750,
      "currency": "cad",
      "status": "succeeded",
      "payment_intent": "pi_abc123xyz",
      "metadata": {
        "order_id": "orders:ord_abc123"
      }
    }
  }
}
```

**Actions**:
- Log charge confirmation
- Update payment records
- (Main order confirmation happens in `payment_intent.succeeded`)

---

### 5. charge.failed
A charge failed (e.g., insufficient funds).

**Payload**:
```json
{
  "id": "evt_mno345...",
  "type": "charge.failed",
  "data": {
    "object": {
      "id": "ch_mno345xyz",
      "status": "failed",
      "failure_code": "card_declined",
      "failure_message": "Your card was declined.",
      "payment_intent": "pi_mno345xyz"
    }
  }
}
```

**Actions**:
- Log failure
- Trigger `payment_intent.payment_failed` logic if not already triggered

---

### 6. charge.refunded
A refund was successfully issued to the customer's card.

**Payload**:
```json
{
  "id": "evt_pqr678...",
  "type": "charge.refunded",
  "data": {
    "object": {
      "id": "ch_pqr678xyz",
      "amount_refunded": 15750,
      "currency": "cad",
      "refunds": {
        "data": [
          {
            "id": "re_pqr678xyz",
            "amount": 15750,
            "status": "succeeded",
            "reason": "requested_by_customer",
            "metadata": {
              "return_id": "returns:ret_pqr678"
            }
          }
        ]
      },
      "metadata": {
        "order_id": "orders:ord_pqr678"
      }
    }
  }
}
```

**Actions**:
1. Fetch corresponding return request from `returns` collection
2. Update return status: `pending` → `approved`
3. Restore product stock (atomic with refund recording)
4. Send "refund processed" email to buyer
5. Update seller's refund statistics (for dispute tracking)

---

### 7. customer.created
A Stripe Connect account was created for a seller.

**Payload**:
```json
{
  "id": "evt_stu901...",
  "type": "customer.created",
  "data": {
    "object": {
      "id": "cus_stu901xyz",
      "email": "seller@example.com",
      "created": 1614556800
    }
  }
}
```

**Actions**:
- Log customer ID mapping to seller
- Update seller's `seller_profiles.stripeCustomerId`

---

### 8. customer.updated
A Stripe customer object was updated.

**Payload**:
```json
{
  "id": "evt_vwx234...",
  "type": "customer.updated",
  "data": {
    "object": {
      "id": "cus_vwx234xyz",
      "email": "seller@example.com",
      "metadata": {
        "seller_id": "users:seller_vwx"
      }
    },
    "previous_attributes": {
      "email": "old@example.com"
    }
  }
}
```

**Actions**:
- Update seller's email/metadata in local `seller_profiles` record if changed

---

### 9. customer.deleted
A Stripe customer was deleted (rare).

**Payload**:
```json
{
  "id": "evt_yza567...",
  "type": "customer.deleted",
  "data": {
    "object": {
      "id": "cus_yza567xyz"
    }
  }
}
```

**Actions**:
- Log deletion
- Mark seller's `seller_profiles.stripeCustomerId` as deleted/null (seller can reinitialize)

---

## Webhook Event Recording (Idempotency)

Every webhook is recorded in the `webhook_events` collection:

```json
{
  "id": "webhook_events:evt_abc123...",
  "eventId": "evt_abc123...",
  "eventType": "payment_intent.succeeded",
  "timestamp": 1614556800,
  "payload": { /* full Stripe event object */ },
  "processed": true,
  "processedAt": 1614556801,
  "orderId": "orders:ord_abc123",  // Extracted from metadata
  "createdAt": 1614556800
}
```

**Duplicate Detection**:
Before processing any webhook:
```sql
SELECT * FROM webhook_events 
WHERE eventId = $event_id AND eventType = $event_type
LIMIT 1;
```

If found, skip processing (already handled).

---

## Error Handling & Retries

### OrignaBase Response Codes

| Code | Meaning | Stripe Action |
|------|---------|---------------|
| **200** | Webhook processed successfully | No retry |
| **202** | Webhook accepted, processing async | No retry |
| **4xx** | Client error (invalid data) | Don't retry |
| **500** | Server error (database down) | Retry with exponential backoff |

**Stripe Retry Policy**:
- Stripe retries 5xx responses with exponential backoff
- First retry: 5 seconds
- Second: 5 minutes
- Third: 30 minutes
- Fourth: 2 hours
- Fifth: 5 hours
- Final: daily for 3 days

If OrignaBase is down for >3 days, events may be lost. Check the Stripe dashboard's Webhooks tab to manually replay events.

### Webhook Timeout

The endpoint must respond within **30 seconds**. If processing takes longer:
- Offload to async task queue (not yet implemented)
- Or return 202 Accepted while processing in background

Currently, complex operations (email, stock update) are inline, so heavy database load could cause timeouts.

---

## Testing Webhooks Locally

### Using Stripe CLI

```bash
# Login to Stripe account
stripe login

# Forward Stripe webhooks to localhost
stripe listen --forward-to localhost:8080/stripe/webhook

# In another terminal, trigger test events
stripe trigger payment_intent.succeeded
```

The Stripe CLI will print the webhook signing secret:
```
> Ready! Your webhook signing secret is STRIPE_WEBHOOK_SECRET_REDACTED...
```

Use this secret in your `.env.dev` for testing.

### Sending Manual Webhook (curl)

```bash
#!/bin/bash

WEBHOOK_SECRET="STRIPE_WEBHOOK_SECRET_REDACTED..."
REQUEST_BODY='{"type":"payment_intent.succeeded","data":{"object":{"id":"pi_test","metadata":{"order_id":"orders:test"}}}}'
TIMESTAMP=$(date +%s)
SIGNED_CONTENT="$TIMESTAMP.$REQUEST_BODY"

# Compute HMAC-SHA256
SIGNATURE=$(echo -n "$SIGNED_CONTENT" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | cut -d' ' -f2)

curl -X POST http://localhost:8080/stripe/webhook \
  -H "Stripe-Signature: t=$TIMESTAMP,v1=$SIGNATURE" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY"
```

---

## Monitoring Webhooks

### View Webhook Delivery History

In Stripe Dashboard:
1. Navigate to **Developers** > **Webhooks**
2. Click the webhook endpoint (e.g., `we_1TBt7u...`)
3. See recent deliveries with status, timestamp, and response code

### Check OrignaBase Webhook Logs

SSH into VPS:
```bash
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16

# Check Docker logs
docker compose -f /opt/orignabase/docker-compose.yml logs orignabase-dev | grep webhook

# Or check structured logs
tail -f /opt/orignabase/logs/webhook_*.log
```

---

## Debugging Webhook Issues

### Issue: Webhook signature verification fails

**Cause**: 
- Wrong webhook secret in `.env`
- Stripe sending to wrong endpoint
- Body was modified in transit

**Fix**:
1. Verify webhook secret in Stripe Dashboard
2. Check endpoint URL in Stripe Dashboard matches your domain
3. Ensure reverse proxy (Caddy) is not buffering/modifying body
4. Add debug logging: `info!(signature = %signature, computed = %computed, "Signature mismatch");`

### Issue: Duplicate orders created

**Cause**: Webhook processed twice without idempotency check.

**Fix**:
- Ensure `webhook_events` query runs before processing
- Use PostgreSQL transaction to atomically check-and-insert
- Set unique constraint on `(eventId, eventType)` if DB supports

### Issue: Webhook never received

**Cause**: 
- Endpoint down/404
- Endpoint returns non-2xx status
- Stripe credentials misconfigured

**Fix**:
1. Check Stripe Dashboard for webhook delivery status
2. Test endpoint manually: `curl https://api.orignagta.ca/stripe/webhook -X POST -H "Stripe-Signature: ..." `
3. Check if Stripe has stopped retrying (after 3 days)
4. Manually replay event: Stripe Dashboard > Webhooks > click endpoint > "Resend"

---

## Stripe Metadata & Order Linking

When creating a Checkout Session, OrignaBase sets metadata:

```rust
let session = client
    .create_checkout_session(CreateCheckoutSession {
        metadata: Some(json!({
            "order_id": "orders:ord_abc123",
            "buyer_id": "users:buyer_xyz"
        }).into()),
        ...
    })
    .await?;
```

When the webhook arrives, extract metadata:

```rust
let order_id = event.data.object.metadata["order_id"].as_str()?;
let order = db.find_by_id(order_id).await?;
```

**Critical**: Always read metadata from `payment_intent.metadata` or `charge.metadata`, NOT from the webhook event root.

---

## Idempotency Best Practices

### For Developers

When processing a webhook:

1. **Immediately check `webhook_events` collection**:
   ```sql
   SELECT * FROM webhook_events 
   WHERE eventId = $event_id 
   LIMIT 1;
   ```

2. **If found, skip processing** (already done)

3. **If not found, process in a transaction**:
   ```sql
   BEGIN TRANSACTION;
   
   INSERT INTO webhook_events (eventId, eventType, payload, processed)
   VALUES ($event_id, $event_type, $payload, true);
   
   UPDATE orders SET status = 'confirmed' WHERE id = $order_id;
   UPDATE products SET stockQuantity = stockQuantity - 1 WHERE id = $product_id;
   
   COMMIT;
   ```

4. **If transaction fails, roll back** (webhook will be retried by Stripe)

### For Stripe

Stripe ensures "at-least-once" delivery:
- Same event may be sent multiple times
- Your code must be idempotent
- Don't rely on order of events

---

## Event Sequence for a Typical Order

1. **Buyer checks out** → OrignaBase creates order in `pending` status
2. **Buyer clicks "Pay"** → Stripe Checkout Session created
3. **Buyer completes payment** → Stripe authorizes amount
4. **charge.succeeded** → Stripe sends webhook
5. **payment_intent.succeeded** → Stripe sends webhook (main confirmation)
6. **OrignaBase processes** → Order status → `confirmed`, stock decremented
7. **Seller sees order** → Dashboard updated
8. **Buyer sees confirmation** → Order details displayed

---

## Future Enhancements

- **Async processing**: Queue webhooks to avoid timeouts
- **Webhook retry logic**: Auto-replay failed webhooks after N days
- **Dead letter queue**: Store unprocessable events for manual review
- **Webhook transformations**: Support Slack/Discord notifications
- **Custom event types**: Support third-party events (Meilisearch index updates, etc.)

---

## Support

For webhook issues:

1. Check Stripe Dashboard: **Developers** > **Webhooks** > endpoint details
2. Search VPS logs: `ssh ... && docker logs orignabase-dev | grep webhook`
3. Run Stripe CLI test: `stripe trigger payment_intent.succeeded`
4. Contact: support@orignagta.ca with webhook event ID

---

**Last Updated**: March 18, 2026  
**Webhook Spec Version**: 1.0  
**Supported Stripe API**: Stripe API v2023-10-16+
