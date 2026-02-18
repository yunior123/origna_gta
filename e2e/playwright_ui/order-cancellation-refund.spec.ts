/**
 * OrignaGTA — Order Cancellation & Refund E2E Tests
 * ===================================================
 * Tests cancellation and refund flows against dev Firebase.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay,
  waitForOrderStatus, getOrder, getProductStock,
  getTestProduct, getSellerAuth,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Order Cancellation & Refund', () => {
  test.setTimeout(180_000);

  let productId: string;
  let productSellerId: string;

  test.beforeAll(async () => {
    const auth = await signIn(BUYER_EMAIL);
    const product = await getTestProduct(auth.idToken, auth.localId);
    productId = product.id;
    productSellerId = product.sellerId;
  });

  test('Buyer can cancel order before shipping', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const cancelResult = await callOk('cancel_order', {
      orderId: result.orderId,
    }, buyerAuth.idToken);

    const order = await getOrder(result.orderId, buyerAuth.idToken);
    expect(order.orderStatus).toBe('cancelled');
  });

  test('Cannot cancel a shipped order', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    // Seller processes and ships
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

    // Buyer tries to cancel — should fail
    const error = await callExpectError('cancel_order', {
      orderId: result.orderId,
    }, buyerAuth.idToken);
    expect(error.code, 'Cannot cancel shipped order').not.toBe('unexpected-success');
  });

  test('Stock restores after cancellation', async ({ page }) => {
    const buyerAuth = await signIn(BUYER_EMAIL);
    const stockBefore = await getProductStock(productId, buyerAuth.idToken);

    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    // Cancel the order
    await callOk('cancel_order', { orderId: result.orderId }, buyerAuth.idToken);

    // Poll for stock restoration (cloud function may have cold start delay)
    const start = Date.now();
    let stockAfter = 0;
    while (Date.now() - start < 30_000) {
      stockAfter = await getProductStock(productId, buyerAuth.idToken);
      if (stockAfter >= stockBefore) break;
      await new Promise(r => setTimeout(r, 2_000));
    }

    // Stock should be restored (or at least not less than before checkout)
    expect(stockAfter).toBeGreaterThanOrEqual(stockBefore);
  });

  test('Cannot cancel an already cancelled order', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    await callOk('cancel_order', { orderId: result.orderId }, buyerAuth.idToken);

    // Try to cancel again — should fail
    const error = await callExpectError('cancel_order', {
      orderId: result.orderId,
    }, buyerAuth.idToken);
    expect(error.code, 'Already cancelled order cannot be cancelled again').not.toBe('unexpected-success');
  });
});
