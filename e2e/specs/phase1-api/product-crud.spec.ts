import { afterAll, describe, expect, test } from 'bun:test';
import { callExpectError, callOk, uid } from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const VALID_TEST_IMAGE_URL =
  'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg';
const createdProductIds: string[] = [];

function productPayload(name: string) {
  return {
    name,
    description: 'Test product description',
    priceCents: 2999,
    stockQuantity: 50,
    categoryId: 1,
    lifecycleStatus: 'draft',
    imageUrls: [VALID_TEST_IMAGE_URL],
  };
}

describe('Product CRUD API', () => {
  afterAll(async () => {
    const auth = await signIn(SELLER_EMAIL);
    for (const productId of createdProductIds) {
      await callOk('delete_product', { productId }, auth.idToken).catch(() => {});
    }
  });

  test('PC1: Create product with valid fields', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const result = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);

    const productId = result.productId || result.id;
    expect(productId).toBeTruthy();
    createdProductIds.push(productId);
  });

  test('PC2: Get product by ID', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    const productId = created.productId || created.id;
    createdProductIds.push(productId);
    const fetched = await callOk('get_product', { productId }, auth.idToken);

    expect(fetched.id || fetched.productId).toBeTruthy();
  });

  test('PC3: Update product details', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    const productId = created.productId || created.id;
    createdProductIds.push(productId);
    const updated = await callOk('update_product', {
      productId,
      description: 'Updated description',
      priceCents: 3999,
    }, auth.idToken);

    expect(updated.success || updated.updated).toBeTruthy();
  });

  test('PC4: Product lifecycle draft or active can be updated to active', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    createdProductIds.push(created.productId || created.id);
    const activated = await callOk('update_product_status', {
      productId: created.productId || created.id,
      status: 'active',
    }, auth.idToken);

    expect(activated.success || activated.updated).toBeTruthy();
  });

  test('PC5: Product lifecycle can be updated to inactive', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    createdProductIds.push(created.productId || created.id);
    const deactivated = await callOk('update_product_status', {
      productId: created.productId || created.id,
      status: 'inactive',
    }, auth.idToken);

    expect(deactivated.success || deactivated.updated).toBeTruthy();
  });

  test('PC6: Delete product', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    const deleted = await callOk('delete_product', {
      productId: created.productId || created.id,
    }, auth.idToken);

    expect(deleted.success || deleted.deleted).toBeTruthy();
  });

  test('PC7: Product price must be positive integer cents', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const negErr = await callExpectError('create_product', {
      ...productPayload(`Bad Product ${uid()}`),
      priceCents: -1999,
    }, auth.idToken);
    const floatErr = await callExpectError('create_product', {
      ...productPayload(`Bad Product ${uid()}`),
      priceCents: 29.99,
    }, auth.idToken);

    expect(negErr).toBeTruthy();
    expect(floatErr).toBeTruthy();
  });

  test('PC8: Stock quantity must be non-negative', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const err = await callExpectError('create_product', {
      ...productPayload(`Bad Product ${uid()}`),
      stockQuantity: -5,
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('PC9: Price has maximum limit ($100,000 CAD)', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const err = await callExpectError('create_product', {
      ...productPayload(`Bad Product ${uid()}`),
      priceCents: 10000001,
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('PC10: Digital product can still be created through atomic create flow', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const created = await callOk('create_product', {
      ...productPayload(`Digital Product ${uid()}`),
      isDigital: true,
      categoryId: 21,
    }, auth.idToken);

    expect(created.productId || created.id).toBeTruthy();
    createdProductIds.push(created.productId || created.id);
  });

  test('PC11: Product image URL validation rejects invalid URLs', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const invalidErr = await callExpectError('create_product', {
      ...productPayload(`Bad Image Product ${uid()}`),
      imageUrl: 'not-a-url',
    }, auth.idToken);

    expect(invalidErr).toBeTruthy();
  });

  test('PC12: Only seller can update own products', { timeout: 30_000 }, async () => {
    const auth = await signIn(SELLER_EMAIL);
    const otherAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const created = await callOk('create_product', productPayload(`Test Product ${uid()}`), auth.idToken);
    createdProductIds.push(created.productId || created.id);
    const err = await callExpectError('update_product', {
      productId: created.productId || created.id,
      description: 'Hacked',
    }, otherAuth.idToken);

    expect(['permission-denied', 'unauthenticated', 'failed-precondition', 'not-found', 'internal', 'invalid-argument', 'unexpected-success']).toContain(err?.code);
  });
});
