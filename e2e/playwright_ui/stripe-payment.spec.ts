/**
 * OrignaGTA — Stripe Payment E2E Tests
 * ======================================
 * Full Stripe Checkout flow against dev Firebase with real Stripe test mode.
 * Each test discovers its own product to avoid stale IDs and stock exhaustion.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk,
  buildCheckoutPayload,
  fillStripeCheckout,
  fullCheckoutAndPay,
  readDoc, parseDoc, listCollection,
  waitForOrderStatus,
  getOrder, getProductStock,
  getTestProduct, invalidateProductCache,
  TEST_ACCOUNTS, STRIPE_CARD, uid,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Stripe Payment Flow', () => {
  test.setTimeout(180_000);

  test('Full checkout → Stripe payment → order confirmed', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, product.id, 1);
    expect(result.orderId).toBeTruthy();
    expect(result.checkoutUrl).toContain('checkout.stripe.com');

    const order = await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);
    expect(order).toBeTruthy();
    expect(order.paymentStatus).toBe('captured');
    expect(order.stripePaymentIntentId).toBeTruthy();
  });

  test('Order document has correct structure after payment', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const { data } = await buildCheckoutPayload(auth.localId, product.id, 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);

    await page.goto(result.checkoutUrl);
    await fillStripeCheckout(page, BUYER_EMAIL);

    const order = await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);
    expect(order.orderId).toBe(result.orderId);
    expect(order.userId).toBe(auth.localId);
    expect(order.currency).toBe('cad');
    expect(order.items.length).toBeGreaterThan(0);
    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.taxAmountCents).toBeGreaterThanOrEqual(0);
    expect(order.totalAmountCents).toBeGreaterThanOrEqual(order.subtotalCents);
    expect(order.shippingAddress).toBeTruthy();
    expect(order.customerEmail).toBeTruthy();
    // Platform fee ratio must be stored at order creation time
    expect(order.platformFeeRatio, 'platformFeeRatio must be 0.025').toBe(0.025);
    expect(order.stripeSessionId, 'stripeSessionId must be stored').toBeTruthy();
  });

  test('Stock decremented by exact ordered quantity after payment', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const stockBefore = await getProductStock(product.id, auth.idToken);
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, product.id, 1);
    await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);

    const stockAfter = await getProductStock(product.id, auth.idToken);
    // Exact delta — not just "less than" (catches over-decrement bugs)
    expect(stockAfter).toBe(stockBefore - 1);
  });

  test('Checkout URL redirects to Stripe hosted page', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const { data } = await buildCheckoutPayload(auth.localId, product.id, 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);

    expect(result.checkoutUrl).toContain('checkout.stripe.com');
    await page.goto(result.checkoutUrl);
    await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
    expect(page.url()).toContain('checkout.stripe.com');
  });

  test('Duplicate checkout with same idempotency key returns same order', async () => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);
    const { data } = await buildCheckoutPayload(auth.localId, product.id, 1, auth.idToken);

    const r1 = await callOk('create_checkout_session', data, auth.idToken);
    const r2 = await callOk('create_checkout_session', data, auth.idToken);
    expect(r1.orderId, 'Duplicate checkout must return same orderId').toBe(r2.orderId);
  });

  test('[BONUS] Order expiresAt is within 7-day authorization window', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, product.id, 1);
    const order = await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);

    if (order.expiresAt) {
      // parseDoc returns timestamps as ISO strings; convert to unix seconds
      const toSec = (ts: any): number =>
        ts?._seconds ?? (typeof ts === 'string' ? Math.floor(new Date(ts).getTime() / 1000) : Number(ts));
      const expiresSec = toSec(order.expiresAt);
      const nowSec = Math.floor(Date.now() / 1000);
      // expiresAt is set when the payment_intent.succeeded webhook fires (7 days from webhook time)
      // Allow ±10 minutes tolerance for test execution time
      expect(expiresSec, 'expiresAt must be ~7 days from now').toBeGreaterThanOrEqual(nowSec + 7 * 86_400 - 600);
      expect(expiresSec, 'expiresAt must be ~7 days from now').toBeLessThanOrEqual(nowSec + 7 * 86_400 + 600);
    }
    // If expiresAt is absent, that's acceptable for auto-capture mode
  });

  test('[BONUS] Cart is cleared after successful order creation', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    await invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, product.id, 1);
    await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);

    // Cart items should be cleared after checkout session creation
    const cartItems = await listCollection(`users/${auth.localId}/cart`, auth.idToken);
    expect(cartItems.length, 'Cart must be empty after successful checkout').toBe(0);
  });
});
