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
  readDoc, parseDoc,
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
    invalidateProductCache();
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
    invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const { data } = await buildCheckoutPayload(auth.localId, product.id, 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);

    await page.goto(result.checkoutUrl);
    await fillStripeCheckout(page, BUYER_EMAIL);
    await page.waitForTimeout(5_000);

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
  });

  test('Stock decremented after successful payment', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const stockBefore = await getProductStock(product.id, auth.idToken);
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, product.id, 1);
    await waitForOrderStatus(result.orderId, ['confirmed', 'processing'], auth.idToken, 90_000);

    const stockAfter = await getProductStock(product.id, auth.idToken);
    expect(stockAfter).toBeLessThan(stockBefore);
  });

  test('Checkout URL redirects to Stripe hosted page', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL);
    invalidateProductCache();
    const product = await getTestProduct(auth.idToken, auth.localId);

    const { data } = await buildCheckoutPayload(auth.localId, product.id, 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);

    expect(result.checkoutUrl).toContain('checkout.stripe.com');
    await page.goto(result.checkoutUrl);
    await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});
    expect(page.url()).toContain('checkout.stripe.com');
  });
});
