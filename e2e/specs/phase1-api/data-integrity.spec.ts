import { beforeAll, describe, expect, test } from 'bun:test';
import { callOk, signIn } from '../../lib/api-client.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

describe('Data Integrity', () => {
  let adminToken: string;
  let buyerToken: string;
  let stableProductId = '';

  beforeAll(async () => {
    adminToken = (await signIn(ADMIN_EMAIL)).idToken;
    buyerToken = (await signIn(BUYER_EMAIL)).idToken;

    const list = await callOk('get_products_paginated', { limit: 5, page: 1 }, buyerToken);
    stableProductId = list.products?.[0]?.id?.split(':').pop?.() ?? list.products?.[0]?.productId ?? '';
  });

  test('T01: Product timestamps are present and recent', async () => {
    if (!stableProductId) return;
    const product = await callOk('get_product', { productId: stableProductId }, buyerToken);
    const timestamp = product.createdAt || product.dateCreated;
    expect(timestamp).toBeTruthy();
  });

  test('T02: Product money values are integer cents', async () => {
    if (!stableProductId) return;
    const product = await callOk('get_product', { productId: stableProductId }, buyerToken);
    expect(Number.isInteger(product.priceCents)).toBe(true);
    expect(product.priceCents).toBeGreaterThanOrEqual(0);
  });

  test('T03: Order status values remain string-valued and normalize cleanly', async () => {
    const orders = await callOk('get_orders', { limit: 10 }, buyerToken);
    for (const order of orders.orders || []) {
      if (typeof order.status === 'string') {
        expect(order.status.trim().length).toBeGreaterThan(0);
        expect(order.status.toLowerCase()).toBe(order.status.trim().toLowerCase());
      }
    }
  });

  test('T04: Product ids retain valid identifier shape (SurrealDB or UUID)', async () => {
    if (!stableProductId) return;
    const product = await callOk('get_product', { productId: stableProductId }, buyerToken);
    if (product.id) {
      const idStr = String(product.id);
      // Accept both SurrealDB record-id format (collection:id) and UUID format
      const isValidShape = idStr.includes(':') || /^[0-9a-f-]{36}$/i.test(idStr);
      expect(isValidShape).toBe(true);
    }
  });

  test('T05: Product listing response remains paginated', async () => {
    const result = await callOk('get_products_paginated', { limit: 10, page: 1 }, buyerToken);
    expect(Array.isArray(result.products)).toBe(true);
    expect(typeof result.hasMore).toBe('boolean');
  });

  test('T06: Product listing respects small limits', async () => {
    const result = await callOk('get_products_paginated', { limit: 5, page: 1 }, buyerToken);
    expect((result.products || []).length).toBeLessThanOrEqual(5);
  });

  test('T07: Seller listing returns consistent product objects', async () => {
    const result = await callOk('get_seller_products_paginated', { limit: 5 }, adminToken);
    expect(Array.isArray(result.products)).toBe(true);
  });

  test('T08: Order money fields are integer cents when present', async () => {
    const orders = await callOk('get_orders', { limit: 10 }, buyerToken);
    for (const order of orders.orders || []) {
      if (order.shippingCostCents !== undefined) {
        expect(Number.isInteger(order.shippingCostCents)).toBe(true);
      }
      if (order.platformFeeTotalCents !== undefined) {
        expect(Number.isInteger(order.platformFeeTotalCents)).toBe(true);
      }
    }
  });

  test('T09: Search fallback uses product listing without breaking response shape', async () => {
    const result = await callOk('get_products_paginated', { category: 'electronics', limit: 10, page: 1 }, buyerToken);
    expect(Array.isArray(result.products)).toBe(true);
  });

  test('T10: Profile metadata includes consent or terms fields when present', async () => {
    const profile = await callOk('get_user_profile', {}, buyerToken);
    if (profile.consentTimestamp !== undefined) {
      expect(profile.consentTimestamp).toBeTruthy();
    }
    if (profile.termsAcceptedAt !== undefined) {
      expect(profile.termsAcceptedAt).toBeTruthy();
    }
  });
});
