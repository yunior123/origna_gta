/**
 * OrignaGTA — Shipping Calculation E2E Tests
 * =============================================
 * Tests shipping cost calculation and tax logic against dev Firebase.
 * Each test discovers its own product to avoid stock exhaustion.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk,
  buildCheckoutPayload,
  readDoc, parseDoc, writeDoc, toFirestoreFields,
  getTestProduct, invalidateProductCache,
  TEST_ACCOUNTS, TEST_UIDS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Shipping Calculation', () => {
  test.setTimeout(120_000);

  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  test.beforeAll(async () => {
    buyerAuth = await signIn(BUYER_EMAIL);
  });

  test('Checkout includes tax calculation for Ontario address', async () => {
    invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 1, buyerAuth.idToken);
    // Ensure Ontario address
    data.shippingAddress.state = 'ON';
    data.shippingAddress.postalCode = 'M5V 3A8';

    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.taxAmountCents).toBeGreaterThan(0);
    expect(order.totalAmountCents).toBeGreaterThan(order.subtotalCents);
    // Ontario HST is 13% — tax applies to subtotal + shipping, so effective rate on subtotal alone can exceed 13%
    const taxableBase = order.subtotalCents + (order.shippingCostCents || 0);
    const expectedTaxMin = Math.floor(taxableBase * 0.10);
    const expectedTaxMax = Math.ceil(taxableBase * 0.16);
    expect(order.taxAmountCents).toBeGreaterThanOrEqual(expectedTaxMin);
    expect(order.taxAmountCents).toBeLessThanOrEqual(expectedTaxMax);
  });

  test('Order total = subtotal + tax + shipping', async () => {
    invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 2, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    const shippingCents = order.shippingCostCents || 0;
    const expectedTotal = order.subtotalCents + order.taxAmountCents + shippingCents;
    // Allow 1 cent rounding tolerance
    expect(Math.abs(order.totalAmountCents - expectedTotal)).toBeLessThanOrEqual(1);
  });

  test('Currency is always CAD', async () => {
    invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 1, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    expect(order.currency).toBe('cad');
  });

  test('Multiple quantity correctly multiplies subtotal', async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);

    const productId = `test_ship_stock_${Date.now()}`;
    await writeDoc(`products/${productId}`, toFirestoreFields({
      sellerId: TEST_UIDS.SELLER,
      sellerSku: `SHIP-TEST-${Date.now()}`,
      name: 'Shipping Test Product',
      price: 10.00,
      isActive: true,
      stockQuantity: 50, // Guaranteed >= 3
      categoryId: 1,
      imageUrls: [],
      keywords: [],
      rating: 0,
    }), adminAuth.idToken);

    const { data: data1 } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
    const result1 = await callOk('create_checkout_session', data1, buyerAuth.idToken);
    const order1 = parseDoc(await readDoc(`orders/${result1.orderId}`, buyerAuth.idToken));

    const { data: data2 } = await buildCheckoutPayload(buyerAuth.localId, productId, 2, buyerAuth.idToken);
    const result2 = await callOk('create_checkout_session', data2, buyerAuth.idToken);
    const order2 = parseDoc(await readDoc(`orders/${result2.orderId}`, buyerAuth.idToken));

    // Subtotal for qty 2 should be ~2x qty 1 (within rounding)
    expect(order2.subtotalCents).toBeGreaterThan(order1.subtotalCents);
    const ratio = order2.subtotalCents / order1.subtotalCents;
    expect(ratio).toBeGreaterThan(1.9);
    expect(ratio).toBeLessThan(2.1);
  });
});
