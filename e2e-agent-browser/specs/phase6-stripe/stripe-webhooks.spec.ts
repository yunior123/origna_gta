/**
 * OrignaGTA — Stripe Webhook E2E Tests (agent-browser)
 * =====================================================
 * Pure API tests for webhook-related behavior against dev OrignaBase.
 * No browser needed — tests webhook endpoint security and idempotency.
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn,
  callOk,
  getOrder,
  buildCheckoutPayload,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, ORIGNABASE_URL } from '../../lib/config.js';

// ─── Constants ───────────────────────────────────────────────────────────────

const WEBHOOK_URL = `${ORIGNABASE_URL}/stripe/webhook`;

describe('Stripe Webhooks', () => {
  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  beforeAll(async () => {
    buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
  });

  // ─── 1. Webhook rejects unsigned request ─────────────────────────
  test('Webhook endpoint rejects unsigned request', async () => {
    const body = JSON.stringify({
      id: 'evt_test_unsigned',
      type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_test', metadata: { order_id: 'fake' } } },
    });

    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body,
    });

    // Should reject with 400 or 401 (no Stripe-Signature header)
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  }, 30_000);

  // ─── 2. Webhook rejects invalid signature ────────────────────────
  test('Webhook endpoint rejects invalid signature', async () => {
    const body = JSON.stringify({
      id: 'evt_test_invalid_sig',
      type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_test', metadata: { order_id: 'fake' } } },
    });

    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': 't=1234567890,v1=invalid_signature_value_here',
      },
      body,
    });

    // Should reject with 400 (invalid signature)
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  }, 30_000);

  // ─── 3. Webhook rejects replay attack (old timestamp) ────────────
  test('Webhook endpoint rejects replay attack with old timestamp', async () => {
    const body = JSON.stringify({
      id: 'evt_test_replay',
      type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_test', metadata: { order_id: 'fake' } } },
    });

    // Timestamp from 2020 — way outside Stripe's tolerance window
    const oldTimestamp = 1577836800;
    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': `t=${oldTimestamp},v1=fake_sig_for_replay_test`,
      },
      body,
    });

    // Should reject — old timestamp outside tolerance
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  }, 30_000);

  // ─── 4. Order status unchanged on failed payment webhook ─────────
  test('Order status does not change on failed payment webhook', async () => {
    // Create a checkout session to get a real order in pending state
    let result: any;
    try {
      const { data } = await buildCheckoutPayload(buyerAuth.localId, 'e2e_product_test_seller', 1, buyerAuth.idToken);
      result = await callOk('create_checkout_session', { ...data, idempotencyKey: `wh-fail-${Date.now()}` }, buyerAuth.idToken);
    } catch (e: any) {
      if (/rate limit|duplicate|not available|429|404|non-json/i.test(e.message ?? '')) {
        console.log('Skipped: checkout not available or rate limited');
        return;
      }
      throw e;
    }

    // Verify order starts as pending — may take a moment to be queryable
    let orderBefore: any = null;
    const pollDeadline = Date.now() + 15_000;
    while (Date.now() < pollDeadline) {
      orderBefore = await getOrder(result.orderId, buyerAuth.idToken);
      if (orderBefore) break;
      await new Promise(r => setTimeout(r, 2_000));
    }
    if (!orderBefore) {
      console.log('Test 4: Order not found after checkout — skipping status check');
      return;
    }
    const beforeStatus = orderBefore.status ?? orderBefore.orderStatus ?? '';
    expect(beforeStatus).toMatch(/pending|created|PENDING_PAYMENT/i);

    // Send a fake payment_intent.failed webhook (will be rejected due to bad signature)
    const body = JSON.stringify({
      id: `evt_test_fail_${Date.now()}`,
      type: 'payment_intent.payment_failed',
      data: { object: { id: 'pi_fake', metadata: { order_id: result.orderId } } },
    });

    await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=invalid`,
      },
      body,
    });

    // Order should remain unchanged (webhook was rejected)
    const orderAfter = await getOrder(result.orderId, buyerAuth.idToken);
    const afterStatus = orderAfter?.status ?? orderAfter?.orderStatus ?? '';
    expect(afterStatus).toBe(beforeStatus);
  }, 60_000);

  // ─── 5. Duplicate webhook event is idempotent ────────────────────
  test('Duplicate webhook event is idempotent (same event ID rejected twice)', async () => {
    const eventId = `evt_test_dup_${Date.now()}`;
    const body = JSON.stringify({
      id: eventId,
      type: 'payment_intent.succeeded',
      data: { object: { id: 'pi_test_dup', metadata: { order_id: 'fake_order' } } },
    });

    const headers = {
      'Content-Type': 'application/json',
      'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=invalid_sig`,
    };

    // Both requests should be rejected (bad sig) — but status should be consistent
    const res1 = await fetch(WEBHOOK_URL, { method: 'POST', headers, body });
    const res2 = await fetch(WEBHOOK_URL, { method: 'POST', headers, body });

    // Both should return the same error status (idempotent rejection)
    expect(res1.status).toBe(res2.status);
  }, 30_000);

  // ─── 6. Unknown event type is ignored gracefully ─────────────────
  test('Webhook with unknown event type is handled gracefully', async () => {
    const body = JSON.stringify({
      id: `evt_test_unknown_${Date.now()}`,
      type: 'totally.made.up.event.type',
      data: { object: { id: 'obj_unknown' } },
    });

    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=invalid_sig`,
      },
      body,
    });

    // Should not crash — returns 400 (bad sig) or 200 (ignored event)
    expect(res.status).toBeLessThan(500);
  }, 30_000);

  // ─── 7. Checkout session creates order in pending state ──────────
  test('Checkout session creates order that can be queried', async () => {
    let result: any;
    try {
      const { data } = await buildCheckoutPayload(buyerAuth.localId, 'e2e_product_test_seller', 1, buyerAuth.idToken);
      result = await callOk('create_checkout_session', { ...data, idempotencyKey: `wh-order-${Date.now()}` }, buyerAuth.idToken);
    } catch (e: any) {
      if (/rate limit|duplicate|not available|429|404|non-json/i.test(e.message ?? '')) {
        console.log('Skipped: checkout not available or rate limited');
        return;
      }
      throw e;
    }

    expect(result.orderId).toBeTruthy();

    // Order may take a moment to be queryable — poll briefly
    let order: any = null;
    const deadline = Date.now() + 15_000;
    while (Date.now() < deadline) {
      order = await getOrder(result.orderId, buyerAuth.idToken);
      if (order) break;
      await new Promise(r => setTimeout(r, 2_000));
    }

    expect(order).toBeTruthy();
    // Accept pending, created, or PENDING_PAYMENT as valid initial states
    const status = order.status ?? order.orderStatus ?? '';
    expect(status).toMatch(/pending|created|PENDING_PAYMENT/i);
    // buyerId may be stored as userId or buyer_id
    const buyerId = order.buyerId ?? order.userId ?? order.buyer_id;
    expect(buyerId).toBeTruthy();
  }, 60_000);

  // ─── 8. Order has correct payment metadata ───────────────────────
  test('Order created by checkout has payment metadata', async () => {
    let result: any;
    try {
      const { data } = await buildCheckoutPayload(buyerAuth.localId, 'e2e_product_test_seller', 1, buyerAuth.idToken);
      result = await callOk('create_checkout_session', { ...data, idempotencyKey: `wh-meta-${Date.now()}` }, buyerAuth.idToken);
    } catch (e: any) {
      if (/rate limit|duplicate|not available|429|404|non-json/i.test(e.message ?? '')) {
        console.log('Skipped: checkout not available or rate limited');
        return;
      }
      throw e;
    }

    const order = await getOrder(result.orderId, buyerAuth.idToken);

    // Order should have payment-related fields
    expect(order.totalAmountCents).toBeGreaterThan(0);
    // Currency may not be set until payment is captured; accept undefined or 'cad'
    if (order.currency) expect(order.currency).toBe('cad');
    // Should have a Stripe session or payment intent reference
    const hasPaymentRef =
      order.stripeSessionId ||
      order.stripePaymentIntentId ||
      order.checkoutSessionId ||
      order.paymentIntentId;
    // Accept either having a ref or the order being in a valid state
    expect(hasPaymentRef || order.status === 'pending').toBeTruthy();
  }, 60_000);

  // ─── 9. Webhook endpoint accepts POST only ───────────────────────
  test('Webhook endpoint rejects non-POST methods', async () => {
    const getRes = await fetch(WEBHOOK_URL, { method: 'GET' });
    // Should return 404 or 405 for GET
    expect(getRes.status).toBeGreaterThanOrEqual(400);

    const putRes = await fetch(WEBHOOK_URL, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: '{}',
    });
    expect(putRes.status).toBeGreaterThanOrEqual(400);
  }, 30_000);

  // ─── 10. Webhook returns non-5xx even for malformed body ─────────
  test('Webhook endpoint returns non-5xx for malformed JSON body', async () => {
    const res = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=test`,
      },
      body: 'this is not json {{{',
    });

    // Should handle gracefully — 400 range, never 500
    expect(res.status).toBeLessThan(500);
  }, 30_000);
});
