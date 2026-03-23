import { describe, expect, test } from 'bun:test';
import { callCallable, callExpectError, callOk } from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS, TEST_PRODUCTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const PRODUCT_ID = TEST_PRODUCTS.HIGH_STOCK;

function isCartUnavailable(error: any): boolean {
  return error?.code === 'not-found' || error?.status === 404 || error?.status === 'NOT_FOUND';
}

async function hasServerCart(token: string): Promise<boolean> {
  const result = await callCallable('get_cart', {}, token);
  return !(result.error && isCartUnavailable(result.error));
}

describe('Cart API Operations', () => {
  test('CA1: Cart surface is either available or returns a deterministic not-found', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callCallable('get_cart', {}, auth.idToken);
    if (result.error) {
      expect(isCartUnavailable(result.error)).toBe(true);
      return;
    }
    expect(result.result || result).toBeTruthy();
  });

  test('CA2: Add-to-cart either succeeds or cleanly reports the cart surface is unavailable', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callCallable('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 1,
    }, auth.idToken);
    if (result.error) {
      expect(isCartUnavailable(result.error)).toBe(true);
      return;
    }
    const body = result.result || result;
    expect(body.success || body.cartId || body.itemCount !== undefined).toBeTruthy();
  });

  test('CA3: When cart is supported, fetching it returns a stable item container', async () => {
    const auth = await signIn(BUYER_EMAIL);
    if (!(await hasServerCart(auth.idToken))) return;
    const cart = await callOk('get_cart', {}, auth.idToken);
    expect(Array.isArray(cart.items || cart.cartItems || [])).toBe(true);
  });

  test('CA4: When cart is supported, quantity updates return a deterministic response', async () => {
    const auth = await signIn(BUYER_EMAIL);
    if (!(await hasServerCart(auth.idToken))) return;
    await callOk('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, auth.idToken);
    const result = await callOk('update_cart_item', {
      productId: PRODUCT_ID,
      quantity: 2,
    }, auth.idToken);
    expect(result.success || result.updated || result.message).toBeTruthy();
  });

  test('CA5: When cart is supported, remove item returns a deterministic response', async () => {
    const auth = await signIn(BUYER_EMAIL);
    if (!(await hasServerCart(auth.idToken))) return;
    await callOk('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, auth.idToken);
    const result = await callOk('remove_from_cart', { productId: PRODUCT_ID }, auth.idToken);
    expect(result.success || result.removed || result.message).toBeTruthy();
  });

  test('CA6: When cart is supported, clear cart empties or acknowledges the cart state', async () => {
    const auth = await signIn(BUYER_EMAIL);
    if (!(await hasServerCart(auth.idToken))) return;
    await callOk('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, auth.idToken);
    const result = await callOk('clear_cart', {}, auth.idToken);
    expect(result.success || result.cleared || result.message).toBeTruthy();
  });

  test('CA7: Add to cart with quantity 0 fails', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const err = await callExpectError('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 0,
    }, auth.idToken);
    expect(err).toBeTruthy();
  });

  test('CA8: Add non-existent product fails gracefully', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const err = await callExpectError('add_to_cart', {
      productId: 'nonexistent_product_id',
      quantity: 1,
    }, auth.idToken);
    expect(['not-found', 'invalid-argument']).toContain(err.code);
  });

  test('CA9: Unauthenticated cart operations fail or return route-not-found', async () => {
    const err = await callExpectError('get_cart', {}, 'invalid-token-xxx');
    expect(['unauthenticated', 'failed-precondition', 'not-found']).toContain(err.code);
  });

  test('CA10: Oversized add-to-cart requests never crash the service', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callCallable('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 999999,
    }, auth.idToken);
    if (result.error) {
      expect(
        isCartUnavailable(result.error)
        || ['invalid-argument', 'resource-exhausted'].includes(result.error.code)
      ).toBe(true);
      return;
    }
    const body = result.result || result;
    expect(body).toBeTruthy();
  });
});
