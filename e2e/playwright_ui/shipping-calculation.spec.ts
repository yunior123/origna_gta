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
  readDoc, parseDoc, writeDoc, deleteDoc, toFirestoreFields,
  getTestProduct, invalidateProductCache,
  TEST_ACCOUNTS, TEST_UIDS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Shipping Calculation', () => {
  test.setTimeout(60_000);

  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  test.beforeAll(async () => {
    buyerAuth = await signIn(BUYER_EMAIL);
  });

  test('Checkout includes tax calculation for Ontario address', async () => {
    await invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    // Use qty=4 to avoid 60s order dedup across repeated runs (unique subtotal for province tax tests)
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 4, buyerAuth.idToken);
    // Ensure Ontario address explicitly
    data.shippingAddress.state = 'ON';
    data.shippingAddress.postalCode = 'M5V 3A8';

    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const doc = await readDoc(`orders/${result.orderId}`, buyerAuth.idToken);
    const order = parseDoc(doc);

    expect(order.subtotalCents).toBeGreaterThan(0);
    expect(order.taxAmountCents).toBeGreaterThan(0);
    expect(order.totalAmountCents).toBeGreaterThan(order.subtotalCents);
    // Ontario HST is exactly 13% — allow ±1 cent for rounding only
    const taxableBase = order.subtotalCents + (order.shippingCostCents || 0);
    const expected13pct = Math.round(taxableBase * 0.13);
    expect(order.taxAmountCents, 'Ontario HST must be exactly 13%').toBeGreaterThanOrEqual(expected13pct - 1);
    expect(order.taxAmountCents, 'Ontario HST must be exactly 13%').toBeLessThanOrEqual(expected13pct + 1);
  });

  test('Order total = subtotal + tax + shipping', async () => {
    await invalidateProductCache();
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
    await invalidateProductCache();
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
      description: 'A test product for shipping calculation E2E tests.',
      price: 10.00,
      priceCents: 1000, // required by backend verify_cart_prices
      lifecycleStatus: 'active',
      stockQuantity: 50,
      categoryId: 1,
      imageUrls: ['https://picsum.photos/400'],
      keywords: [],
    }), adminAuth.idToken);

    try {
      const { data: data1 } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);
      const result1 = await callOk('create_checkout_session', data1, buyerAuth.idToken);
      const order1 = parseDoc(await readDoc(`orders/${result1.orderId}`, buyerAuth.idToken));

      const { data: data2 } = await buildCheckoutPayload(buyerAuth.localId, productId, 2, buyerAuth.idToken);
      const result2 = await callOk('create_checkout_session', data2, buyerAuth.idToken);
      const order2 = parseDoc(await readDoc(`orders/${result2.orderId}`, buyerAuth.idToken));

      // Pin exact values (product price is known: $10.00)
      expect(order1.subtotalCents).toBe(1000);
      expect(order2.subtotalCents).toBe(2000);
    } finally {
      // Always clean up the test product to avoid polluting dev Firestore
      await deleteDoc(`products/${productId}`, adminAuth.idToken).catch(() => {});
    }
  });

  test('Quebec address applies QST+GST tax rate (~14.975%)', async () => {
    await invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    // Use qty=5 to avoid 60s order dedup with Ontario/other tests (unique subtotal for province tax tests)
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 5, buyerAuth.idToken);
    data.shippingAddress.state = 'QC';
    data.shippingAddress.postalCode = 'H2X 1Y6';

    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const order = parseDoc(await readDoc(`orders/${result.orderId}`, buyerAuth.idToken));

    const taxableBase = order.subtotalCents + (order.shippingCostCents || 0);
    // QC: GST 5% + QST 9.975% = 14.975% total
    const expectedQC = Math.round(taxableBase * 0.14975);
    expect(order.taxAmountCents, 'QC tax must be ~14.975%').toBeGreaterThanOrEqual(expectedQC - 2);
    expect(order.taxAmountCents, 'QC tax must be ~14.975%').toBeLessThanOrEqual(expectedQC + 2);
  });

  test('Alberta address applies GST-only tax rate (5%)', async () => {
    await invalidateProductCache();
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    // Use qty=6 to avoid 60s order dedup across repeated runs (unique subtotal for province tax tests)
    const { data } = await buildCheckoutPayload(buyerAuth.localId, product.id, 6, buyerAuth.idToken);
    data.shippingAddress.state = 'AB';
    data.shippingAddress.postalCode = 'T2P 1J9';

    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const order = parseDoc(await readDoc(`orders/${result.orderId}`, buyerAuth.idToken));

    const taxableBase = order.subtotalCents + (order.shippingCostCents || 0);
    // AB: GST only = 5%
    const expected5pct = Math.round(taxableBase * 0.05);
    expect(order.taxAmountCents, 'AB tax must be exactly 5% GST').toBeGreaterThanOrEqual(expected5pct - 1);
    expect(order.taxAmountCents, 'AB tax must be exactly 5% GST').toBeLessThanOrEqual(expected5pct + 1);
  });

  test('International seller uses national ceiling shipping cost ($26.99)', async () => {
    const products = await discoverProducts();
    const intlProduct = products.find(p => p.id === 'e2e_product_intl_seller');
    if (!intlProduct) throw new Error('International test product missing');

    const { data } = await buildCheckoutPayload(buyerAuth.localId, intlProduct.id, 1, buyerAuth.idToken);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);
    const order = parseDoc(await readDoc(`orders/${result.orderId}`, buyerAuth.idToken));

    // National ceiling is $26.99 = 2699 cents
    expect(order.shippingCostCents).toBe(2699);
  });
});
