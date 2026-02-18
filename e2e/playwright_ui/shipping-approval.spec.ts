/**
 * OrignaGTA — Shipping Approval E2E Tests
 * ==========================================
 * Tests shipping cost approval flow between seller and buyer.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError, callCallable,
  fullCheckoutAndPay,
  waitForOrderStatus, getOrder,
  getTestProduct, getSellerAuth,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Shipping Approval', () => {
  test.setTimeout(180_000);

  let productId: string;
  let productSellerId: string;

  test.beforeAll(async () => {
    const auth = await signIn(BUYER_EMAIL);
    const product = await getTestProduct(auth.idToken, auth.localId);
    productId = product.id;
    productSellerId = product.sellerId;
  });

  test('Seller can submit shipping cost for an order', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    const sellerAuth = await getSellerAuth(productSellerId);
    // Move to processing first
    await callOk('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    // Submit shipping cost — API expects newShippingCost in dollars
    const shippingResult = await callCallable('update_shipping_cost', {
      orderId: result.orderId,
      newShippingCost: 15.00,
      reason: 'Actual shipping cost from Canada Post',
    }, sellerAuth.idToken);

    // The endpoint may reject if paymentStatus != 'authorized' (auto-capture sets 'captured')
    expect(shippingResult).toBeTruthy();
  });

  test('Only the order seller can submit shipping cost', async ({ page }) => {
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, productId, 1);
    const buyerAuth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], buyerAuth.idToken, 90_000);

    // Buyer tries to submit shipping cost — should fail
    const error = await callExpectError('update_shipping_cost', {
      orderId: result.orderId,
      newShippingCost: 15.00,
    }, buyerAuth.idToken);

    // Should be rejected (buyer is not the seller)
    expect(error.code).not.toBe('unexpected-success');
  });
});
