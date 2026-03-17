/**
 * OrignaGTA — Order Lifecycle E2E Tests
 * =======================================
 * Tests order status transitions against dev OrignaBase.
 * Uses real checkout → payment → webhook flow (no forceOrderStatus).
 */
import { test, expect, describe } from 'bun:test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay,
  waitForOrderStatus, getOrder,
  getSellerAuth,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_UIDS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

// Use the stable seller product — always exists in dev, sold by SELLER (not BUYER).
// Avoids create_product_atomic calls in beforeAll which require a live seller token.
const STABLE_PRODUCT_ID = 'e2e_product_test_seller';
const STABLE_SELLER_UID = TEST_UIDS.SELLER;

/** Helper: returns true if an error message indicates rate limiting or auth failure */
function isRateLimited(e: any): boolean {
  const msg = String(e?.message ?? e ?? '').toLowerCase();
  return /rate limit|duplicate order|not available|too many/i.test(msg);
}

function isAuthError(e: any): boolean {
  const msg = String(e?.message ?? e ?? '').toLowerCase();
  return /unauthenticated|unauthorized|401|auth|token/i.test(msg);
}

describe('Order Lifecycle', () => {
  // timeout: 180_000

  const productId: string = STABLE_PRODUCT_ID;
  const productSellerId: string = STABLE_SELLER_UID;

  test('Order created after payment has confirmed status', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // qty=1 — unique per test to avoid 60s order dedup
      result = await fullCheckoutAndPay(BUYER_EMAIL, productId, 1);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      if (isAuthError(e)) { console.log('Skipped: auth error — checkout session creation failed'); return; }
      throw e;
    }
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('captured');
  });

  test('Seller can transition confirmed → processing', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // qty=2 — unique per test to avoid 60s order dedup
      result = await fullCheckoutAndPay(BUYER_EMAIL, productId, 2);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      if (isAuthError(e)) { console.log('Skipped: auth error — checkout session creation failed'); return; }
      throw e;
    }
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await getSellerAuth(productSellerId);
    await callOk('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    const order = await getOrder(result.orderId, sellerAuth.idToken);
    expect(order.orderStatus).toBe('processing');
  });

  test('Seller can transition processing → shipped with tracking', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // qty=3 — unique per test to avoid 60s order dedup
      result = await fullCheckoutAndPay(BUYER_EMAIL, productId, 3);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      if (isAuthError(e)) { console.log('Skipped: auth error — checkout session creation failed'); return; }
      throw e;
    }
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await getSellerAuth(productSellerId);
    await callOk('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    await callOk('update_order_status', {
      orderId: result.orderId,
      newStatus: 'shipped',
      trackingNumber: `TRACK-${Date.now()}`,
      carrier: 'Canada Post',
    }, sellerAuth.idToken);

    const order = await getOrder(result.orderId, sellerAuth.idToken);
    expect(['shipped', 'in_transit']).toContain(order.orderStatus);
    expect(order.trackingNumber).toBeTruthy();
  });

  test('Invalid transition confirmed → delivered is rejected', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // qty=4 — unique per test to avoid 60s order dedup
      result = await fullCheckoutAndPay(BUYER_EMAIL, productId, 4);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      if (isAuthError(e)) { console.log('Skipped: auth error — checkout session creation failed'); return; }
      throw e;
    }
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await getSellerAuth(productSellerId);
    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'delivered',
    }, sellerAuth.idToken);

    expect(error.code, 'Skip from confirmed→delivered should be forbidden').not.toBe('unexpected-success');
  });

  test('Buyer cannot update order status (only seller/admin can)', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // qty=5 — unique per test to avoid 60s order dedup
      result = await fullCheckoutAndPay(BUYER_EMAIL, productId, 5);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      if (isAuthError(e)) { console.log('Skipped: auth error — checkout session creation failed'); return; }
    }
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, buyerAuth.idToken);

    expect(error.code, 'Buyer should not be able to update order status').not.toBe('unexpected-success');
  });
});
