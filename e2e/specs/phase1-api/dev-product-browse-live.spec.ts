import { describe, expect, test } from 'bun:test';
import { ORIGNABASE_URL } from '../../lib/config.js';

const GRAPHQL_URL = `${ORIGNABASE_URL}/graphql`;
const ALL_CATEGORY_IDS = Array.from({ length: 21 }, (_, index) => index + 1);

async function listProducts(
  filters: Record<string, unknown>,
  options: { limit?: number; startAfter?: string } = {},
) {
  const response = await fetch(GRAPHQL_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      query:
        'query($collection:String!,$filters:JSON,$orderBy:String,$descending:Boolean,$limit:Int,$startAfter:String){ list(collection:$collection, filters:$filters, orderBy:$orderBy, descending:$descending, limit:$limit, startAfter:$startAfter) }',
      variables: {
        collection: 'products',
        filters,
        orderBy: 'createdAt',
        descending: true,
        limit: options.limit ?? 10,
        startAfter: options.startAfter,
      },
    }),
  });

  const body = await response.json();
  return { response, body };
}

async function listProductsPage(offset: number) {
  const response = await fetch(GRAPHQL_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      query:
        'query($collection:String!,$filters:JSON,$orderBy:String,$descending:Boolean,$limit:Int,$offset:Int){ list(collection:$collection, filters:$filters, orderBy:$orderBy, descending:$descending, limit:$limit, offset:$offset) }',
      variables: {
        collection: 'products',
        filters: {
          lifecycleStatus: { _eq: 'active' },
        },
        orderBy: 'createdAt',
        descending: true,
        limit: 100,
        offset,
      },
    }),
  });

  const body = await response.json();
  return { response, body };
}

describe('Dev product browse live contract', () => {
  test('every storefront category query stays healthy', async () => {
    for (const categoryId of ALL_CATEGORY_IDS) {
      const { response, body } = await listProducts({
        lifecycleStatus: { _eq: 'active' },
        categoryId: { _eq: categoryId },
      });

      expect(response.status).toBe(200);
      expect(body.errors).toBeUndefined();
      expect(Array.isArray(body.data?.list)).toBe(true);
    }
  });

  test('category-filtered product listing does not return internal server error', async () => {
    const { response, body } = await listProducts({
      lifecycleStatus: { _eq: 'active' },
      categoryId: { _eq: 1 },
    });

    expect(response.status).toBe(200);
    expect(body.errors).toBeUndefined();
    expect(Array.isArray(body.data?.list)).toBe(true);
  });

  test('search keyword listing does not return internal server error', async () => {
    const { response, body } = await listProducts({
      lifecycleStatus: { _eq: 'active' },
      keywords: { _contains: 'laptop' },
    });

    expect(response.status).toBe(200);
    expect(body.errors).toBeUndefined();
    expect(Array.isArray(body.data?.list)).toBe(true);
    expect(body.data.list.length).toBeGreaterThan(0);
  });

  test('combined category + search listing remains healthy', async () => {
    const { response, body } = await listProducts({
      lifecycleStatus: { _eq: 'active' },
      categoryId: { _eq: 2 },
      keywords: { _contains: 'laptop' },
    });

    expect(response.status).toBe(200);
    expect(body.errors).toBeUndefined();
    expect(Array.isArray(body.data?.list)).toBe(true);
    expect(body.data.list.length).toBeGreaterThan(0);
  });

  test('seeded active catalog covers all 21 storefront categories and keeps images on products', async () => {
    const seen = new Set<number>();

    for (let offset = 0; offset < 500; offset += 100) {
      const { response, body } = await listProductsPage(offset);
      expect(response.status).toBe(200);
      expect(body.errors).toBeUndefined();

      const list = Array.isArray(body.data?.list) ? body.data.list : [];
      for (const product of list) {
        const categoryId = Number(product.categoryId);
        if (Number.isFinite(categoryId) && categoryId >= 1 && categoryId <= 21) {
          seen.add(categoryId);
        }
        const imageUrls = Array.isArray(product.imageUrls) ? product.imageUrls : [];
        expect(imageUrls.length).toBeGreaterThan(0);
      }

      if (list.length < 100) {
        break;
      }
    }

    expect([...seen].sort((a, b) => a - b)).toEqual(ALL_CATEGORY_IDS);
  });

  test('cursor pagination remains healthy across multiple home-feed pages', async () => {
    let startAfter: string | undefined;

    for (let page = 0; page < 5; page += 1) {
      const { response, body } = await listProducts(
        {
          lifecycleStatus: { _eq: 'active' },
        },
        { limit: 20, startAfter },
      );

      expect(response.status).toBe(200);
      expect(body.errors).toBeUndefined();
      expect(Array.isArray(body.data?.list)).toBe(true);
      expect(body.data.list.length).toBeGreaterThan(0);

      startAfter = body.data.list.at(-1)?.id;
      if (!startAfter) {
        break;
      }
    }
  });
});
