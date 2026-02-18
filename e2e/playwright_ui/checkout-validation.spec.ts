/**
 * OrignaGTA — Checkout Validation E2E Tests
 * ==========================================
 * Tests checkout input validation against dev Firebase.
 * No emulators — all requests hit orignagta-dev deployed functions.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  readDoc, parseDoc,
  buildCheckoutPayload,
  TEST_ACCOUNTS, FUNCTIONS_URL,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Checkout Validation', () => {
  test.setTimeout(60_000);

  test('Rejects unauthenticated checkout request', async () => {
    const res = await fetch(`${FUNCTIONS_URL}/create_checkout_session`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: {} }),
    });
    const body = await res.json();
    expect(body.error || res.status !== 200).toBeTruthy();
  });

  test('Rejects empty items array', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const error = await callExpectError('create_checkout_session', {
      userId: auth.localId,
      items: [],
      subtotal: 0,
      shippingAddress: {
        street: '1 Test St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
    }, auth.idToken);
    expect(error.code, 'Empty items should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects missing shipping address fields', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    data.shippingAddress = { street: '1 Test' }; // Missing required fields
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Missing address fields should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects invalid postal code format', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    data.shippingAddress.postalCode = 'INVALID';
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Invalid postal code should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects price tampering (client sends lower price)', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    data.items[0].price = 0.01;
    data.subtotal = 0.01;
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Price tampering should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects subtotal mismatch', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    data.subtotal = data.subtotal + 999;
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Subtotal mismatch should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects negative price', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    data.items[0].price = -50.00;
    data.subtotal = -50.00;
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Negative price should be rejected').not.toBe('unexpected-success');
  });

  test('Rejects quantity zero', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 0, auth.idToken);
    data.items[0].quantity = 0;
    data.subtotal = 0;
    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Zero quantity should be rejected').not.toBe('unexpected-success');
  });

  test('Valid checkout creates session with Stripe URL', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);
    const result = await callOk('create_checkout_session', data, auth.idToken);

    expect(result.orderId, 'Should return orderId').toBeTruthy();
    expect(result.checkoutUrl, 'Should return Stripe checkout URL').toContain('checkout.stripe.com');

    // Verify order document created in Firestore
    const doc = await readDoc(`orders/${result.orderId}`, auth.idToken);
    const order = parseDoc(doc);
    expect(order, 'Order doc should exist').toBeTruthy();
    expect(order.orderStatus).toBe('pending');
    expect(order.currency).toBe('cad');
    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.totalAmountCents).toBeGreaterThan(0);
  });
});
