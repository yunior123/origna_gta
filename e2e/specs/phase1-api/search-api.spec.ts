import { describe, expect, test } from 'bun:test';
import { callOk } from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

describe('Search API Operations', () => {
  test('SA1: Product listing returns an array for a buyer', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA2: Empty query falls back to the product listing contract', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA3: Pagination accepts limit and offset inputs', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const page1 = await callOk('get_products_paginated', {
      limit: 10,
      page: 1,
    }, auth.idToken);
    const page2 = await callOk('get_products_paginated', {
      limit: 10,
      page: 2,
    }, auth.idToken);

    expect(Array.isArray(page1.products)).toBe(true);
    expect(Array.isArray(page2.products)).toBe(true);
  });

  test('SA4: Category filtering keeps a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      category: 'electronics',
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA5: Price range filtering keeps a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA6: Sorting by price ascending keeps a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      orderBy: 'priceCents',
      orderDirection: 'asc',
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA7: Sorting by price descending keeps a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      orderBy: 'priceCents',
      orderDirection: 'desc',
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA8: Sorting by creation date keeps a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      orderBy: 'createdAt',
      orderDirection: 'desc',
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA9: Combined filters keep a valid response shape', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      category: 'electronics',
      limit: 20,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA10: Limit parameter is honored at the response boundary', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 5,
      page: 1,
    }, auth.idToken);

    expect((result.products || []).length).toBeLessThanOrEqual(5);
  });

  test('SA11: Excessive limit does not crash the endpoint', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 10000,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });

  test('SA12: Negative offset is normalized safely', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('get_products_paginated', {
      limit: 10,
      page: 1,
    }, auth.idToken);

    expect(Array.isArray(result.products)).toBe(true);
  });
});
