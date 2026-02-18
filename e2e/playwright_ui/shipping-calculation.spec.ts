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
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Shipping Calculation', () => {
  test.setTimeout(60_000);

  test('Checkout includes tax calculation for Ontario address', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    // Ensure Ontario address
    data.shippingAddress.state = 'ON';
    data.shippingAddress.postalCode = 'M5V 3A8';

    const result = await callOk('create_checkout_session', data, auth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, auth.idToken);
    const order = parseDoc(doc);

    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.taxAmountCents).toBeGreaterThan(0);
    expect(order.totalAmountCents).toBeGreaterThan(order.subtotalCents);
    // Ontario HST is 13%
    const expectedTaxMin = Math.floor(order.subtotalCents * 0.10);
    const expectedTaxMax = Math.ceil(order.subtotalCents * 0.16);
    expect(order.taxAmountCents).toBeGreaterThanOrEqual(expectedTaxMin);
    expect(order.taxAmountCents).toBeLessThanOrEqual(expectedTaxMax);
  });

  test('Order total = subtotal + tax + shipping', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 2, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, auth.idToken);
    const order = parseDoc(doc);

    const shippingCents = order.shippingCostCents || 0;
    const expectedTotal = order.subtotalCents + order.taxAmountCents + shippingCents;
    // Allow 1 cent rounding tolerance
    expect(Math.abs(order.totalAmountCents - expectedTotal)).toBeLessThanOrEqual(1);
  });

  test('Currency is always CAD', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, auth.idToken);
    const order = parseDoc(doc);

    expect(order.currency).toBe('cad');
  });

  test('Multiple quantity correctly multiplies subtotal', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data: data1 } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    const result1 = await callOk('create_checkout_session', data1, auth.idToken);
    const order1 = parseDoc(await readDoc(`orders/${result1.orderId}`, auth.idToken));

    const { data: data2 } = await buildCheckoutPayload(auth.localId, 'product_001', 2, auth.idToken);
    const result2 = await callOk('create_checkout_session', data2, auth.idToken);
    const order2 = parseDoc(await readDoc(`orders/${result2.orderId}`, auth.idToken));

    // Subtotal for qty 2 should be ~2x qty 1 (within rounding)
    expect(order2.subtotalCents).toBeGreaterThan(order1.subtotalCents);
    const ratio = order2.subtotalCents / order1.subtotalCents;
    expect(ratio).toBeGreaterThan(1.9);
    expect(ratio).toBeLessThan(2.1);
  });
});
