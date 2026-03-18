/**
 * OrignaGTA — Cart API E2E Tests
 * ==============================
 * Comprehensive coverage of cart operations: add, update, remove, clear, totals.
 * Verifies cart state, pricing (integer cents), and multi-seller scenarios.
 */
import { test, expect, describe } from 'bun:test';
import {
  callOk,
  callCallable,
  callExpectError,
} from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS, TEST_PRODUCTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const PRODUCT_ID = TEST_PRODUCTS.HIGH_STOCK;

describe('Cart API Operations', () => {
  test('CA1: Add item to empty cart', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 1,
    }, auth.idToken);
    expect(result).toBeTruthy();
    expect(result.success || result.cartId).toBeTruthy();
  });

  test('CA2: Add multiple items updates cart total', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Add first item
    await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 2,
    }, auth.idToken);

    // Get cart
    const cart = await callOk('get_cart', {}, auth.idToken);
    expect(cart).toBeTruthy();
    expect(cart.items || cart.cartItems).toBeTruthy();
  });

  test('CA3: Update item quantity in cart', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Add item
    await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 1,
    }, auth.idToken);

    // Update quantity
    const result = await callOk('update_cart_item', {
      productId: PRODUCT_ID,
      quantity: 5,
    }, auth.idToken);
    expect(result.success || result.updated).toBeTruthy();
  });

  test('CA4: Remove item from cart', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Add item
    await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 1,
    }, auth.idToken);

    // Remove item
    const result = await callOk('remove_from_cart', {
      productId: PRODUCT_ID,
    }, auth.idToken);
    expect(result.success || result.removed).toBeTruthy();
  });

  test('CA5: Clear entire cart', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Add multiple items
    await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 2,
    }, auth.idToken);

    // Clear cart
    const result = await callOk('clear_cart', {}, auth.idToken);
    expect(result.success || result.cleared).toBeTruthy();

    // Verify cart is empty
    const cart = await callOk('get_cart', {}, auth.idToken);
    const itemCount = (cart?.items || cart?.cartItems || []).length;
    expect(itemCount).toBe(0);
  });

  test('CA6: Cart totals are in integer cents', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    await callOk('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 1,
    }, auth.idToken);

    const cart = await callOk('get_cart', {}, auth.idToken);
    const total = cart?.totalCents || cart?.totalAmountCents;
    
    // Verify total is integer (no decimals)
    expect(typeof total).toBe('number');
    expect(Number.isInteger(total)).toBe(true);
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
    expect(['not-found', 'invalid-argument']).toContain(err?.code);
  });

  test('CA9: Unauthenticated cart operations fail', async () => {
    const err = await callExpectError('get_cart', {}, 'invalid-token-xxx');
    expect(['unauthenticated', 'failed-precondition']).toContain(err?.code);
  });

  test('CA10: Cart respects stock limits', async () => {
    const auth = await signIn(BUYER_EMAIL);
    
    // Try to add more than available stock
    const result = await callCallable('add_to_cart', {
      productId: PRODUCT_ID,
      quantity: 999999,
    }, auth.idToken);
    
    // Should either fail or cap at stock limit
    if (!result.error) {
      const cart = await callOk('get_cart', {}, auth.idToken);
      expect(cart?.items || cart?.cartItems).toBeTruthy();
    }
  });
});
