/**
 * OrignaGTA — Order Lifecycle E2E Tests
 * =======================================
 * Tests order status transitions against dev OrignaBase.
 * Uses real checkout → payment → webhook flow (no forceOrderStatus).
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay,
  waitForOrderStatus, getOrder,
  getSellerAuth,
  TEST_ACCOUNTS, TEST_UIDS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

// Use the stable seller product — always exists in dev, sold by SELLER (not BUYER).
// Avoids create_product_atomic calls in beforeAll which require a live seller token.
const STABLE_PRODUCT_ID = 'e2e_product_test_seller';
const STABLE_SELLER_UID = TEST_UIDS.SELLER;

test.describe('Order Lifecycle', () => {
  test.setTimeout(180_000);

  const productId: string = STABLE_PRODUCT_ID;
  const productSellerId: string = STABLE_SELLER_UID;

  test('Order created after payment has confirmed status', async ({ page }) => {
    // qty=1 — unique per test to avoid 60s order dedup
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('captured');
  });

  test('Seller can transition confirmed → processing', async ({ page }) => {
    // qty=2 — unique per test to avoid 60s order dedup
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 2);
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

  test('Seller can transition processing → shipped with tracking', async ({ page }) => {
    // qty=3 — unique per test to avoid 60s order dedup
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 3);
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

  test('Invalid transition confirmed → delivered is rejected', async ({ page }) => {
    // qty=4 — unique per test to avoid 60s order dedup
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 4);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await getSellerAuth(productSellerId);
    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'delivered',
    }, sellerAuth.idToken);

    expect(error.code, 'Skip from confirmed→delivered should be forbidden').not.toBe('unexpected-success');
  });

  test('Buyer cannot update order status (only seller/admin can)', async ({ page }) => {
    // qty=5 — unique per test to avoid 60s order dedup
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 5);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, buyerAuth.idToken);

    expect(error.code, 'Buyer should not be able to update order status').not.toBe('unexpected-success');
  });
});
