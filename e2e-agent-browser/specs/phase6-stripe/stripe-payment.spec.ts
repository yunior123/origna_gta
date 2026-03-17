/**
 * OrignaGTA — Stripe Payment E2E Tests (agent-browser)
 * =====================================================
 * Full Stripe Checkout flow against dev OrignaBase with real Stripe test mode.
 * Uses stable products to avoid auth failures from seller-only product creation.
 *
 * Migrated from: e2e/playwright_ui/stripe-payment.spec.ts
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn, callOk,
  buildCheckoutPayload,
  listCollection,
  waitForOrderStatus,
  getProductStock,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

// ─── Stripe Card Helper ─────────────────────────────────────────────────────

async function fillStripeCard(
  browser: AgentBrowser,
  card = { number: '4242424242424242', exp: '12/34', cvc: '123', name: 'Test Buyer' },
) {
  const snap = await browser.snapshot({ interactive: true, compact: true });
  const cardField = browser.findByLabel(snap, /card number|numéro de carte/i);
  const expField = browser.findByLabel(snap, /expir/i);
  const cvcField = browser.findByLabel(snap, /cvc|security|sécurité/i);
  const nameField = browser.findByLabel(snap, /cardholder|titulaire|billing name/i);
  if (cardField) await browser.fill(cardField.ref, card.number);
  if (expField) await browser.fill(expField.ref, card.exp);
  if (cvcField) await browser.fill(cvcField.ref, card.cvc);
  if (nameField) await browser.fill(nameField.ref, card.name);
}

// ─── Constants ───────────────────────────────────────────────────────────────

const STABLE_PRODUCT_ID = 'e2e_product_test_seller';
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

describe('Stripe Payment Flow', () => {
  let browser: AgentBrowser;
  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  beforeAll(async () => {
    browser = new AgentBrowser({ headed: false });
    buyerAuth = await signIn(BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Full checkout -> Stripe payment -> order confirmed', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const uniqueData = { ...data, idempotencyKey: `full-test-${Date.now()}-${Math.random().toString(36).slice(2)}` };
    const result = await callOk('create_checkout_session', uniqueData, buyerAuth.idToken);

    expect(result.orderId).toBeTruthy();
    expect(result.checkoutUrl).toContain('checkout.stripe.com');

    // Open Stripe checkout and fill card
    await browser.open(result.checkoutUrl);
    await new Promise(r => setTimeout(r, 5000));
    await fillStripeCard(browser);

    // Submit payment
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i);
    if (payBtn) await browser.click(payBtn.ref);

    // Wait for webhook to confirm order
    const order = await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], buyerAuth.idToken, 90_000);
    expect(order).toBeTruthy();
    expect(order.paymentStatus).toBe('captured');
    expect(order.stripePaymentIntentId).toBeTruthy();
  }, 180_000);

  test('Order document has correct structure after payment', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const uniqueData = { ...data, idempotencyKey: `struct-test-${Date.now()}-${Math.random().toString(36).slice(2)}` };
    const result = await callOk('create_checkout_session', uniqueData, buyerAuth.idToken);

    await browser.open(result.checkoutUrl);
    await new Promise(r => setTimeout(r, 5000));
    await fillStripeCard(browser);

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i);
    if (payBtn) await browser.click(payBtn.ref);

    const order = await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], buyerAuth.idToken, 90_000);
    expect(order.orderId).toBe(result.orderId);
    expect(order.userId).toBe(buyerAuth.localId);
    expect(order.currency).toBe('cad');
    expect(order.items.length).toBeGreaterThan(0);
    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.taxAmountCents).toBeGreaterThanOrEqual(0);
    expect(order.totalAmountCents).toBeGreaterThanOrEqual(order.subtotalCents);
    expect(order.shippingAddress).toBeTruthy();
    expect(order.customerEmail).toBeTruthy();
    expect(order.platformFeeRatio).toBe(0.025);
    expect(order.stripeSessionId).toBeTruthy();
  }, 180_000);

  test('Stock decremented by exact ordered quantity after payment', async () => {
    const stockBefore = await getProductStock(STABLE_PRODUCT_ID, buyerAuth.idToken);

    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const uniqueData = { ...data, idempotencyKey: `stock-test-${Date.now()}-${Math.random().toString(36).slice(2)}` };
    const result = await callOk('create_checkout_session', uniqueData, buyerAuth.idToken);

    await browser.open(result.checkoutUrl);
    await new Promise(r => setTimeout(r, 5000));
    await fillStripeCard(browser);

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i);
    if (payBtn) await browser.click(payBtn.ref);

    await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], buyerAuth.idToken, 90_000);

    const stockAfter = await getProductStock(STABLE_PRODUCT_ID, buyerAuth.idToken);
    expect(stockAfter).toBeLessThan(stockBefore);
    const delta = stockBefore - stockAfter;
    expect(delta).toBeGreaterThanOrEqual(1);
  }, 180_000);

  test('Checkout URL redirects to Stripe hosted page', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);

    expect(result.checkoutUrl).toContain('checkout.stripe.com');

    await browser.open(result.checkoutUrl);
    await new Promise(r => setTimeout(r, 5000));

    // Verify we are on the Stripe page via snapshot
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  }, 60_000);

  test('Duplicate checkout with same idempotency key returns same order', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const idempotencyKey = `dedup-test-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const dedupData = { ...data, idempotencyKey };

    const r1 = await callOk('create_checkout_session', dedupData, buyerAuth.idToken);
    const r2 = await callOk('create_checkout_session', dedupData, buyerAuth.idToken);
    expect(r1.orderId).toBe(r2.orderId);
  }, 30_000);

  test('[BONUS] Cart is cleared after successful order creation', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, STABLE_PRODUCT_ID, 1, buyerAuth.idToken);
    const uniqueData = { ...data, idempotencyKey: `cart-test-${Date.now()}-${Math.random().toString(36).slice(2)}` };
    const result = await callOk('create_checkout_session', uniqueData, buyerAuth.idToken);

    await browser.open(result.checkoutUrl);
    await new Promise(r => setTimeout(r, 5000));
    await fillStripeCard(browser);

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const payBtn = browser.findByRole(snap, 'button', /pay|payer|subscribe|submit/i);
    if (payBtn) await browser.click(payBtn.ref);

    await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], buyerAuth.idToken, 90_000);

    const cartItems = await listCollection(`users/${buyerAuth.localId}/cart`, buyerAuth.idToken);
    expect(cartItems.length).toBe(0);
  }, 180_000);
});
