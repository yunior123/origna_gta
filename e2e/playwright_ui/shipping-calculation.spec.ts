/**
 * OrignaGTA — Shipping Calculation E2E Tests
 * =============================================
 * Tests shipping cost calculation and tax logic against dev Firebase.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk,
  buildCheckoutPayload,
  readDoc, parseDoc,
  getTestProduct,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Shipping Calculation', () => {
  test.setTimeout(60_000);

  let productId: string;
  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  test.beforeAll(async () => {
    buyerAuth = await signIn(BUYER_EMAIL);
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    productId = product.id;
  });

  test('Checkout includes tax calculation for Ontario address', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
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
    const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 2, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    const shippingCents = order.shippingCostCents || 0;
    const expectedTotal = order.subtotalCents + order.taxAmountCents + shippingCents;
    // Allow 1 cent rounding tolerance
    expect(Math.abs(order.totalAmountCents - expectedTotal)).toBeLessThanOrEqual(1);
  });

  test('Currency is always CAD', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    expect(order.currency).toBe('cad');
  });

  test('Multiple quantity correctly multiplies subtotal', async () => {
    // This test creates 2 checkout sessions (qty=1 and qty=2). Needs stock >= 3.
    // Skip if the product doesn't have enough stock.
    const prodDoc = await readDoc(`products/${productId}`, buyerAuth.idToken);
    const product = parseDoc(prodDoc);
    const stock = product?.stockQuantity ?? 0;
    test.skip(stock < 3, `Product has only ${stock} stock, need >= 3 for this test`);

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
