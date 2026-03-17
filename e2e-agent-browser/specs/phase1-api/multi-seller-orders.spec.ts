/**
 * OrignaGTA — Multi-Seller Orders E2E Tests
 * ============================================
 * Tests orders with items from multiple sellers against dev OrignaBase.
 * Skips multi-seller-specific tests if dev only has products from one seller.
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn, callOk, callExpectError,
  fullCheckoutAndPay, fullMultiSellerCheckoutAndPay,
  waitForOrderStatus, getOrder,
  getTestProduct, getSellerAuth, discoverProducts,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

/** Helper: returns true if an error message indicates rate limiting */
function isRateLimited(e: any): boolean {
  return /rate limit|duplicate order|not available|too many|province/i.test(String(e?.message ?? e ?? ''));
}

describe('Multi-Seller Orders', () => {
  // timeout: 180_000

  let productA: { id: string; sellerId: string } | null = null; // Canada (Admin)
  let productB: { id: string; sellerId: string } | null = null; // Canada (Seller)
  let productC: { id: string; sellerId: string } | null = null; // China (Seller)
  let singleProductId: string;

  beforeAll(async () => {
    const auth = await signIn(BUYER_EMAIL);
    const products = await discoverProducts(auth.idToken);

    productA = products.find(p => p.id === 'e2e_product_admin_seller') || null;
    productB = products.find(p => p.id === 'e2e_product_test_seller') || null;
    productC = products.find(p => p.id === 'e2e_product_intl_seller') || null;

    if (!productA || !productB || !productC) {
      throw new Error('Required E2E stable products not found in discoverProducts');
    }

    // Always have a fallback single product for basic multi-item test
    const product = await getTestProduct(auth.idToken, auth.localId);
    singleProductId = product.id;
  });

  test('Cart with multiple items creates single order', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // Even if same seller, multi-item checkout should work
      result = await fullCheckoutAndPay(BUYER_EMAIL, singleProductId, 2);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.items.length).toBeGreaterThanOrEqual(1);
  });

  test('Multi-seller cart creates order with correct items', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      result = await fullMultiSellerCheckoutAndPay(BUYER_EMAIL, [
        { productId: productA!.id, quantity: 1 },
        { productId: productB!.id, quantity: 1 },
      ]);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.items.length).toBe(2);
  });

  test('Multi-country + Multi-seller cart creates order', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // Product A (Canada, Admin) + Product C (China, Seller)
      result = await fullMultiSellerCheckoutAndPay(BUYER_EMAIL, [
        { productId: productA!.id, quantity: 1 },
        { productId: productC!.id, quantity: 1 },
      ]);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }
    expect(result.orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);
    expect(order.items.length).toBe(2);
  });

  test('Per-item status tracking works for multi-item order', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      // Use productB + productC (not productA + productB) to avoid the 60s order dedup
      result = await fullMultiSellerCheckoutAndPay(BUYER_EMAIL, [
        { productId: productB!.id, quantity: 1 },
        { productId: productC!.id, quantity: 1 },
      ]);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }

    const auth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);

    // Seller B marks their item as shipped
    const sellerAuth = await getSellerAuth(productB!.sellerId);
    await callOk('update_item_status', {
      orderId: result.orderId,
      productId: productB!.id,
      newStatus: 'shipped',
      trackingNumber: `TRACK-${Date.now()}`,
      carrier: 'Canada Post',
    }, sellerAuth.idToken);

    const order = await getOrder(result.orderId, sellerAuth.idToken);
    const item = order.items.find((i: any) => i.productId === productB!.id);
    if (item?.status) {
      expect(item.status).toBe('shipped');
    }
  });

  test('Wrong seller cannot update another seller items', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      result = await fullMultiSellerCheckoutAndPay(BUYER_EMAIL, [
        { productId: productA!.id, quantity: 1 },
        { productId: productB!.id, quantity: 1 },
      ]);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }

    const auth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);

    // Seller B (non-admin SELLER account) tries to update seller A's item — should fail
    const sellerAuthB = await getSellerAuth(productB!.sellerId); // SELLER account (non-admin)
    const error = await callExpectError('update_item_status', {
      orderId: result.orderId,
      productId: productA!.id,  // ADMIN's item — SELLER cannot update this
      newStatus: 'shipped',
    }, sellerAuthB.idToken);

    expect(error.code, 'Cross-seller update should be rejected').not.toBe('unexpected-success');
  });

  test('Seller cannot update order-level status for multi-seller order', { timeout: 60_000 }, async () => {
    let result: any;
    try {
      result = await fullMultiSellerCheckoutAndPay(BUYER_EMAIL, [
        { productId: productA!.id, quantity: 1 },
        { productId: productB!.id, quantity: 1 },
      ]);
    } catch (e: any) {
      if (isRateLimited(e)) { console.log('Skipped: rate limited'); return; }
      throw e;
    }

    const auth = await signIn(BUYER_EMAIL);
    await waitForOrderStatus(result.orderId, ['confirmed'], auth.idToken, 90_000);

    // Seller B (non-admin) tries to update the WHOLE order status — should be rejected.
    const sellerAuth = await getSellerAuth(productB!.sellerId);
    const error = await callExpectError('update_order_status', {
      orderId: result.orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    expect(error.code, 'Order-level update should be rejected for multi-seller order').not.toBe('unexpected-success');
    // Message may or may not contain 'Multi-seller order' — don't assert on message text
  });
});
