/**
 * OrignaGTA — Order Lifecycle E2E Tests
 * =======================================
 * Tests order status transitions against dev Firebase.
 * Uses real checkout → payment → webhook flow (no forceOrderStatus).
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay,
  waitForOrderStatus, getOrder,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const PRODUCT_ID = 'product_001';

test.describe('Order Lifecycle', () => {
  test.setTimeout(180_000);

  test('Order created after payment has confirmed status', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('captured');
  });

  test('Seller can transition confirmed → processing', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await signIn(SELLER_EMAIL);
    await callOk('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    const order = await getOrder(result.orderId, sellerAuth.idToken);
    expect(order.orderStatus).toBe('processing');
  });

  test('Seller can transition processing → shipped with tracking', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await signIn(SELLER_EMAIL);
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
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await signIn(SELLER_EMAIL);
    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'delivered',
    }, sellerAuth.idToken);

    expect(error.code, 'Skip from confirmed→delivered should be forbidden').not.toBe('unexpected-success');
  });

  test('Buyer cannot update order status (only seller/admin can)', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, buyerAuth.idToken);

    expect(error.code, 'Buyer should not be able to update order status').not.toBe('unexpected-success');
  });
});
