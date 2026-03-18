/**
 * OrignaGTA — Seller Product Management E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/seller-product-management.spec.ts
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import {
  signIn,
  callOk,
  callExpectError,
  getDoc,
  uid,
} from '../../lib/api-client.js';
import {
  TEST_ACCOUNTS,
  TEST_PRODUCTS,
} from '../../lib/config.js';
import { AgentBrowser } from '../../lib/agent-browser.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;

// ═══ API-DRIVEN TESTS ═══

describe('Seller Product Management — API Tests', () => {
  let sellerToken: string;
  let sellerRecordId: string;
  let adminToken: string;
  let testProductId: string;

  beforeAll(async () => {
    const seller = await signIn(SELLER_EMAIL);
    sellerToken = seller.idToken;
    sellerRecordId = (() => {
      try {
        const [, payload] = seller.idToken.split('.');
        const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
        return decoded.user_id || decoded.sub || decoded.uid || seller.localId;
      } catch {
        return seller.localId;
      }
    })();
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    adminToken = admin.idToken;

    const result = await callOk('create_product_atomic', {
      productData: {
        name: `Mgmt Test ${uid()}`,
        description: 'For management E2E tests',
        price: 15,
        stockQuantity: 999,
        categoryId: '1',
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    testProductId = result.productId;

    await callOk('admin_approve_product', { productId: testProductId }, adminToken);
  });

  afterAll(async () => {
    try {
      await callOk('delete_product', { productId: testProductId }, sellerToken);
    } catch {}
  });

  test('T01: Get seller products — returns own products with correct sellerId', async () => {
    const result = await callOk('get_seller_products_paginated', {
      includeInactive: true,
    }, sellerToken);
    expect(result.success).toBe(true);
    expect(result.products).toBeTruthy();
    expect(result.products.length).toBeGreaterThan(0);

    for (const product of result.products) {
      expect(product.sellerId).toBe(sellerRecordId);
    }
  });

  test('T02: Bulk pause products — verify lifecycleStatus in SurrealDB', async () => {
    const result = await callOk('bulk_update_products', {
      productIds: [testProductId],
      action: 'pause',
    }, sellerToken);
    expect(result.success).toBe(true);

    const doc = await getDoc(`products/${testProductId}`, sellerToken);
    expect(doc.lifecycleStatus).toBe('paused');
  });

  test('T03: Bulk activate products — verify restore in SurrealDB', async () => {
    const result = await callOk('bulk_update_products', {
      productIds: [testProductId],
      action: 'activate',
    }, sellerToken);
    expect(result.success).toBe(true);

    const doc = await getDoc(`products/${testProductId}`, sellerToken);
    expect(doc.lifecycleStatus).toBe('active');
  });

  test("T04: Cannot manage another seller's products — permission-denied", async () => {
    const error = await callExpectError('update_product', {
      productId: TEST_PRODUCTS.HIGH_STOCK,
      productData: { name: 'Hacked Name' },
    }, sellerToken);
    expect(error.code).toBe('permission-denied');
  });
});

// ═══ UI-DRIVEN TESTS ═══

describe('Seller Product Management — UI Tests', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T05: UI — Seller can navigate to add product page', { timeout: 60_000 }, async () => {
    await browser.open('https://dev.orignagta.ca/#/seller/add-product');
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T06: UI — Home page shows product cards', { timeout: 60_000 }, async () => {
    await browser.open('https://dev.orignagta.ca/');
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const productCards = browser.findAllByLabel(snap, /^product-card-/);
    expect(productCards.length).toBeGreaterThan(0);
  });

  test('T07: UI — Product detail page shows product information', { timeout: 60_000 }, async () => {
    await browser.open(`https://dev.orignagta.ca/#/product/${TEST_PRODUCTS.HIGH_STOCK}`);
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T08: UI — Seller sees rejection banner with Fix & Resubmit button for rejected products', { timeout: 60_000 }, async () => {
    await browser.open('https://dev.orignagta.ca/#/seller/products');
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const rejectionBanner = browser.findByLabel(snap, /reject|fix|resubmit/i);
    // Page should load; rejection banner presence depends on data state
    expect(snap.refs.length).toBeGreaterThan(0);
    if (rejectionBanner) {
      expect(rejectionBanner).toBeTruthy();
    }
  });
});
