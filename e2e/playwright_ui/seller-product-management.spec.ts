import { test, expect } from '@playwright/test';
import {
  waitForFlutter, requireWebApp, checkSemantics,
  ensureLoggedInAsAdmin, performSignOut, navigateHome,
  BTN_ADD_PRODUCT,
} from './flutter-helpers';
import {
  signIn, callOk, callExpectError, getDoc, uid,
  TEST_ACCOUNTS, WEB_APP_URL, TEST_PRODUCTS,
} from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASS = TEST_ACCOUNTS.SELLER_PASS;
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;

// ═══ API-DRIVEN TESTS ═══

test.describe('Seller Product Management — API Tests', () => {
  test.setTimeout(120_000);
  test.describe.configure({ mode: 'serial' });

  let sellerToken: string;
  let sellerUid: string;
  let adminToken: string;
  let testProductId: string;

  test.beforeAll(async () => {
    const seller = await signIn(SELLER_EMAIL);
    sellerToken = seller.idToken;
    sellerUid = seller.localId;
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    adminToken = admin.idToken;

    // Create a digital test product (no address verification = no geocoding timeout)
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

    // Approve it so it can be paused/activated
    await callOk('admin_approve_product', { productId: testProductId }, adminToken);
  });

  test.afterAll(async () => {
    // Cleanup
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

    // Every returned product should belong to this seller
    for (const product of result.products) {
      expect(product.sellerId).toBe(sellerUid);
    }
  });

  test('T02: Bulk pause products — verify lifecycleStatus in Firestore', async () => {
    const result = await callOk('bulk_update_products', {
      productIds: [testProductId],
      action: 'pause',
    }, sellerToken);
    expect(result.success).toBe(true);

    const doc = await getDoc(`products/${testProductId}`, sellerToken);
    expect(doc.lifecycleStatus).toBe('paused');
  });

  test('T03: Bulk activate products — verify restore in Firestore', async () => {
    const result = await callOk('bulk_update_products', {
      productIds: [testProductId],
      action: 'activate',
    }, sellerToken);
    expect(result.success).toBe(true);

    const doc = await getDoc(`products/${testProductId}`, sellerToken);
    expect(doc.lifecycleStatus).toBe('active');
  });

  test('T04: Cannot manage another seller\'s products — permission-denied', async () => {
    // Seller1 trying to update a product owned by admin
    const error = await callExpectError('update_product', {
      productId: TEST_PRODUCTS.HIGH_STOCK, // Admin's product
      productData: { name: 'Hacked Name' },
    }, sellerToken);
    expect(error.code).toBe('permission-denied');
  });
});

// ═══ UI-DRIVEN TESTS ═══

test.describe('Seller Product Management — UI Tests', () => {
  test.setTimeout(300_000);

  test('T05: UI — Seller can navigate to add product page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASS);

    const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    await expect(addProductBtn).toBeVisible({ timeout: 20000 });
    await addProductBtn.click();
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('T06: UI — Seller sees own product cards on home page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASS);

    // Scroll to find product cards
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    // At least some products should be visible
    expect(await productCards.count()).toBeGreaterThan(0);

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('T07: UI — Product detail page shows product information', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // No login needed — product detail is public
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    if ((await productCards.count()) > 0) {
      const homeUrl = page.url();
      await productCards.first().click();
      await page.waitForTimeout(3000);
      await waitForFlutter(page);
      // Product detail loads data from Firestore — allow extra time after Flutter is ready
      await page.waitForTimeout(5000);
      // Scroll down to bring product action buttons into Flutter's accessibility tree
      // (Flutter only exposes off-screen Semantics nodes once they scroll into view)
      await page.mouse.wheel(0, 600);
      await page.waitForTimeout(1_000);

      // Should navigate to a detail page
      expect(page.url()).not.toBe(homeUrl);

      // Look for product detail content — at least one UI element must be visible.
      // Covers: in-stock (add to cart), own product (seller view), or out-of-stock (notify me).
      const addToCartBtn = page.locator('[aria-label^="product_add_to_cart_button"]').first();
      const ownProductMsg = page.locator('[aria-label="product_own_product_message"]').first();
      const notifyMeBtn = page.locator('[aria-label^="product_notify_me_button"],[aria-label^="product_notify_section"]').first();
      const hasCart = await addToCartBtn.isVisible({ timeout: 15_000 }).catch(() => false);
      const hasOwnMsg = await ownProductMsg.isVisible({ timeout: 5000 }).catch(() => false);
      const hasNotify = await notifyMeBtn.isVisible({ timeout: 5000 }).catch(() => false);
      expect(hasCart || hasOwnMsg || hasNotify).toBe(true);

      await page.goBack();
      await waitForFlutter(page);
    }
  });
});
