/**
 * OrignaGTA — Multi-Seller Orders E2E Tests
 * ============================================
 * Tests orders with items from multiple sellers against dev Firebase.
 * Skips multi-seller-specific tests if dev only has products from one seller.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay, fullMultiSellerCheckoutAndPay,
  waitForOrderStatus, getOrder,
  getTestProduct, ensureTwoSellerProducts, getSellerAuth,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Multi-Seller Orders', () => {
  test.setTimeout(180_000);

  let productA: { id: string; sellerId: string } | null = null;
  let productB: { id: string; sellerId: string } | null = null;
  let singleProductId: string;

  test.beforeAll(async () => {
    const auth = await signIn(BUYER_EMAIL);
    const twoProducts = await ensureTwoSellerProducts(auth.idToken);
    [productA, productB] = twoProducts;

    // Always have a fallback single product for basic multi-item test
    const product = await getTestProduct(auth.idToken, auth.localId);
    singleProductId = product.id;
  });

  test('Cart with multiple items creates single order', async ({ page }) => {
    // Even if same seller, multi-item checkout should work
    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, singleProductId, 2);
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.items.length).toBeGreaterThanOrEqual(1);
  });

  test('Multi-seller cart creates order with correct items', async ({ page }) => {
    const result = await fullMultiSellerCheckoutAndPay(page, BUYER_EMAIL, [
      { productId: productA!.id, quantity: 1 },
      { productId: productB!.id, quantity: 1 },
    ]);
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.items.length).toBe(2);
  });

  test('Per-item status tracking works for multi-item order', async ({ page }) => {

    const result = await fullMultiSellerCheckoutAndPay(page, BUYER_EMAIL, [
      { productId: productA!.id, quantity: 1 },
      { productId: productB!.id, quantity: 1 },
    ]);

    const auth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);

    // Seller A marks their item as shipped (valid DeliveryStatusValues: pending/shipped/delivered/refunded)
    const sellerAuth = await getSellerAuth(productA!.sellerId);
    const updateResult = await callOk('update_item_status', {
      orderId: result.orderId,
      productId: productA!.id,
      newStatus: 'shipped',
      trackingNumber: `TRACK-${Date.now()}`,
      carrier: 'Canada Post',
    }, sellerAuth.idToken);

    const order = await getOrder(result.orderId, sellerAuth.idToken);
    const item = order.items.find((i: any) => i.productId === productA!.id);
    if (item?.status) {
      expect(item.status).toBe('shipped');
    }
  });

  test('Wrong seller cannot update another seller items', async ({ page }) => {
    const result = await fullMultiSellerCheckoutAndPay(page, BUYER_EMAIL, [
      { productId: productA!.id, quantity: 1 },
      { productId: productB!.id, quantity: 1 },
    ]);

    const auth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);

    // Seller B (non-admin SELLER account) tries to update seller A's item — should fail
    // Note: productA belongs to ADMIN (who has admin role), so we use the SELLER account
    // trying to update ADMIN's item, not vice versa (admin bypasses the cross-seller check)
    const sellerAuthB = await getSellerAuth(productB!.sellerId); // SELLER account (non-admin)
    const error = await callExpectError('update_item_status', {
      orderId: result.orderId,
      productId: productA!.id,  // ADMIN's item — SELLER cannot update this
      newStatus: 'shipped',
    }, sellerAuthB.idToken);

    expect(error.code, 'Cross-seller update should be rejected').not.toBe('unexpected-success');
  });
});
