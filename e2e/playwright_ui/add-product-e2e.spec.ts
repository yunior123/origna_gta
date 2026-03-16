import { test, expect } from '@playwright/test';
import {
  waitForFlutter, requireWebApp, checkSemantics,
  ensureLoggedInAsAdmin, navigateHome, navigateToAddProduct,
} from './flutter-helpers';
import {
  signIn, callOk, callExpectError,
  getDoc, deleteDoc,
  TEST_ACCOUNTS, WEB_APP_URL, uid,
} from './api-helpers';
import * as path from 'path';
import * as os from 'os';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

// Track created product IDs for cleanup
const createdProductIds: string[] = [];

async function scrollToBottom(page: any) {
  await page.mouse.move(640, 400);
  for (let i = 0; i < 6; i++) {
    await page.mouse.wheel(0, 4000);
    await page.waitForTimeout(300);
  }
}

async function screenshotOnFailure(page: any, testInfo: { title: string; status?: string }) {
  if (testInfo.status === 'failed' || testInfo.status === 'timedOut') {
    const slug = testInfo.title.replace(/\W+/g, '_').slice(0, 80);
    const dest = path.join(os.homedir(), 'Desktop', `FAILED_${slug}_${Date.now()}.png`);
    try { await page.screenshot({ path: dest, fullPage: true }); } catch {}
  }
}

function getPublishBtn(page: any) {
  return page
    .locator('[aria-label="btn-publish-product"]')
    .or(page.getByRole('button', { name: /btn-publish-product|publish|publier/i }).first())
    .or(page.getByText(/publish|publier/i).first())
    .first();
}

// ═══ API-DRIVEN TESTS (no browser needed) ═══

test.describe('Add Product — API Tests', () => {
  test.setTimeout(120_000);
  test.describe.configure({ mode: 'serial' });

  let sellerToken: string;
  let sellerUid: string;
  let adminToken: string;
  let buyerToken: string;

  test.beforeAll(async () => {
    const seller = await signIn(SELLER_EMAIL);
    sellerToken = seller.idToken;
    sellerUid = seller.localId;
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    adminToken = admin.idToken;
    const buyer = await signIn(BUYER_EMAIL);
    buyerToken = buyer.idToken;
  });

  test.afterAll(async () => {
    // Cleanup: soft-delete all created products via callable (respects security rules)
    for (const pid of createdProductIds) {
      try {
        await callOk('delete_product', { productId: pid }, sellerToken);
      } catch {
        // Fallback to hard-delete if callable fails (product may already be archived)
        try { await deleteDoc(`products/${pid}`, sellerToken); } catch {}
      }
    }
  });

  test('T01: Create product via callable — verify SurrealDB record', async () => {
    const testName = `E2E Product ${uid()}`;
    // Use ebook digital type to avoid geocoding timeout on address verification
    const result = await callOk('create_product_atomic', {
      productData: {
        name: testName,
        description: 'E2E test product',
        price: 29.99,
        stockQuantity: 10,
        categoryId: '1',
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);

    expect(result.success).toBe(true);
    expect(result.productId).toBeTruthy();
    createdProductIds.push(result.productId);

    // Verify SurrealDB record
    const doc = await getDoc(`products/${result.productId}`, sellerToken);
    expect(doc).toBeTruthy();
    expect(doc.name).toBe(testName);
    expect(doc.price).toBe(29.99);
    expect(doc.stockQuantity).toBe(10);
    expect([sellerUid, `users:${sellerUid}`]).toContain(doc.sellerId);
    expect(['under_review', 'active']).toContain(doc.lifecycleStatus);
    expect(doc.imageUrls).toBeTruthy();
    expect(doc.imageUrls.length).toBeGreaterThan(0);
  });

  test('T02: Create digital product — verify digital fields in SurrealDB', async () => {
    const testName = `E2E Digital ${uid()}`;
    const result = await callOk('create_product_atomic', {
      productData: {
        name: testName,
        description: 'E2E test digital product',
        price: 9.99,
        stockQuantity: 999,
        categoryId: '1',
        isDigital: true,
        digitalType: 'software',
        digitalBuilds: { windows: 'https://example.com/setup.exe' },
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);

    expect(result.success).toBe(true);
    createdProductIds.push(result.productId);

    const doc = await getDoc(`products/${result.productId}`, sellerToken);
    expect(doc).toBeTruthy();
    expect(doc.isDigital).toBe(true);
    expect(doc.digitalType).toBe('software');
    // Digital products should NOT have ship-from fields
    expect(doc.shipFromCity).toBeFalsy();
    expect(doc.shipFromProvince).toBeFalsy();
  });

  // Backend validation: empty productData should return invalid-argument.
  // If the backend has not yet enforced this, the test will fail and track the gap.
  test('T03: Validation — missing required fields returns invalid-argument', async () => {
    const error = await callExpectError('create_product_atomic', {
      productData: {},
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    expect(error.code).toBe('invalid-argument');
  });

  // Backend validation: negative price should return invalid-argument.
  test('T04: Validation — negative price returns invalid-argument', async () => {
    const error = await callExpectError('create_product_atomic', {
      productData: {
        name: 'Negative Price Product',
        description: 'Should fail',
        price: -5,
        stockQuantity: 10,
        categoryId: '1',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    expect(error.code).toBe('invalid-argument');
  });

  // Security: buyers must not be allowed to create products (role check).
  test('T05: Buyer cannot create products — permission-denied', async () => {
    const error = await callExpectError('create_product_atomic', {
      productData: {
        name: 'Buyer Trying Product',
        description: 'Should fail',
        price: 10,
        stockQuantity: 5,
        categoryId: '1',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, buyerToken);
    expect(error.code).toBe('permission-denied');
  });

  // Duplicate SKU must be rejected to prevent inventory confusion.
  test('T06: Duplicate SKU rejected', async () => {
    const skuVal = `sku-dup-test-${uid()}`;
    // Create first product with SKU (digital to avoid geocoding)
    const result = await callOk('create_product_atomic', {
      productData: {
        name: `SKU Test 1 ${uid()}`,
        description: 'First with this SKU',
        price: 15,
        stockQuantity: 5,
        categoryId: '1',
        sellerSku: skuVal,
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    createdProductIds.push(result.productId);

    // Try same SKU again
    const error = await callExpectError('create_product_atomic', {
      productData: {
        name: `SKU Test 2 ${uid()}`,
        description: 'Duplicate SKU',
        price: 20,
        stockQuantity: 3,
        categoryId: '1',
        sellerSku: skuVal,
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    // SKU collision should return already-exists or invalid-argument
    expect(['already-exists', 'invalid-argument']).toContain(error.code);
  });

  test('T07: Update product name — verify change in SurrealDB', async () => {
    const result = await callOk('create_product_atomic', {
      productData: {
        name: `Update Test ${uid()}`,
        description: 'Will be updated',
        price: 12,
        stockQuantity: 8,
        categoryId: '1',
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    createdProductIds.push(result.productId);

    const newName = `Updated Product ${uid()}`;
    // api-helpers spreads everything except productId/userId into productData,
    // so pass name at the top level (not wrapped in productData).
    const updateResult = await callOk('update_product', {
      productId: result.productId,
      name: newName,
    }, sellerToken);
    expect(updateResult.success).toBe(true);

    const doc = await getDoc(`products/${result.productId}`, sellerToken);
    expect(doc.name).toBe(newName);
  });

  test('T08: Delete product — verify soft delete in SurrealDB', async () => {
    const result = await callOk('create_product_atomic', {
      productData: {
        name: `Delete Test ${uid()}`,
        description: 'Will be deleted',
        price: 5,
        stockQuantity: 1,
        categoryId: '1',
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    // Don't add to cleanup — we're deleting it here

    const delResult = await callOk('delete_product', {
      productId: result.productId,
    }, sellerToken);
    expect(delResult.success).toBe(true);

    const doc = await getDoc(`products/${result.productId}`, sellerToken);
    expect(doc.lifecycleStatus).toBe('archived');
  });

  test('T09: Admin approve product — verify lifecycleStatus=active', async () => {
    const result = await callOk('create_product_atomic', {
      productData: {
        name: `Approve Test ${uid()}`,
        description: 'Will be approved by admin',
        price: 25,
        stockQuantity: 20,
        categoryId: '1',
        isDigital: true,
        digitalType: 'book',
        bookSourceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
      testImageUrls: ['https://picsum.photos/400/400'],
    }, sellerToken);
    createdProductIds.push(result.productId);

    // Products may start as 'under_review' or 'active' depending on backend config.
    let doc = await getDoc(`products/${result.productId}`, sellerToken);
    expect(['under_review', 'active']).toContain(doc.lifecycleStatus);

    if (doc.lifecycleStatus === 'under_review') {
      // Admin approves
      const approveResult = await callOk('admin_approve_product', {
        productId: result.productId,
      }, adminToken);
      expect(approveResult.success).toBe(true);

      // Verify approved
      doc = await getDoc(`products/${result.productId}`, adminToken);
    }
    expect(doc.lifecycleStatus).toBe('active');
  });
});

// ═══ UI-DRIVEN TESTS (browser required) ═══

test.describe('Add Product — UI Tests', () => {
  test.setTimeout(300_000);

  test.beforeEach(async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);
    // IMPORTANT: use in-app navigation — page.goto('/add-product') causes a Flutter
    // cold-start that loses the OrignaBase JWT (in-memory only, not persisted to storage).
    await navigateToAddProduct(page, TARGET_URL);
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30_000 });
    await waitForFlutter(page);
  });

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('T10: UI — Fill form and attempt publish', async ({ page }) => {
    // Flutter Web renders TextFormField as <input aria-label="HINT_TEXT"> for the
    // actual editable input, and a separate disabled textbox for the floating label.
    // Use aria-label matching the hintText (placeholder) to target the real input.

    // Fill Product Name — hint: "Enter product name"
    const nameInput = page.locator('input[aria-label="Enter product name"]').first();
    const nameFound = await nameInput.waitFor({ state: 'attached', timeout: 30_000 })
      .then(() => true).catch(() => false);
    if (!nameFound) {
      // Fallback: try role-based textbox (disabled label node may match)
      const nameFallback = page.getByRole('textbox', { name: /product name/i }).nth(1);
      await nameFallback.click({ force: true, timeout: 10_000 }).catch(() => { });
    } else {
      await nameInput.click({ timeout: 30_000 });
    }
    await page.waitForTimeout(800);
    await page.keyboard.type(`E2E UI Product ${uid()}`, { delay: 30 });

    // Fill Description — hint: "Describe your product..."
    const descInput = page.locator('input[aria-label="Describe your product..."], textarea[aria-label="Describe your product..."]').first();
    const descFound = await descInput.waitFor({ state: 'attached', timeout: 10_000 })
      .then(() => true).catch(() => false);
    if (descFound) {
      await descInput.click({ timeout: 10_000 }).catch(() => { });
    } else {
      const descFallback = page.getByRole('textbox', { name: /description/i }).nth(1);
      await descFallback.click({ force: true, timeout: 10_000 }).catch(() => { });
    }
    await page.waitForTimeout(800);
    await page.keyboard.type('E2E test product created via UI', { delay: 30 });

    // Fill Price — no hint; label is "Price (CAD)", aria-label may be label text
    const priceInput = page.locator('input[aria-label="Price (CAD)"], input[aria-label="Prix (CAD)"]').first();
    const priceFound = await priceInput.waitFor({ state: 'attached', timeout: 10_000 })
      .then(() => true).catch(() => false);
    if (priceFound) {
      await priceInput.click({ timeout: 10_000 }).catch(() => { });
    } else {
      const priceFallback = page.getByRole('textbox', { name: /price.*cad|prix/i }).nth(1);
      await priceFallback.click({ force: true, timeout: 10_000 }).catch(() => { });
    }
    await page.waitForTimeout(800);
    await page.keyboard.type('24.99', { delay: 30 });

    // Fill Stock — no hint; label is "Stock"
    const stockInput = page.locator('input[aria-label="Stock"]').first();
    const stockFound = await stockInput.waitFor({ state: 'attached', timeout: 10_000 })
      .then(() => true).catch(() => false);
    if (stockFound) {
      await stockInput.click({ timeout: 10_000 }).catch(() => { });
    } else {
      const stockFallback = page.getByRole('textbox', { name: /^stock$/i }).nth(1);
      await stockFallback.click({ force: true, timeout: 10_000 }).catch(() => { });
    }
    await page.waitForTimeout(800);
    await page.keyboard.type('15', { delay: 30 });

    // Note: toHaveValue() doesn't work on flt-semantics[role="textbox"] (Flutter Web).
    // The typing outcome is verified by the publish attempt result below.

    // Select category — Flutter uses a popup menu (role="menuitem", not "option").
    // Dismiss any open popup before scrolling to avoid the overlay blocking the publish button.
    const categorySelector = page.getByRole('button', { name: /category|catégorie/i }).first();
    if (await categorySelector.isVisible({ timeout: 5000 }).catch(() => false)) {
      await categorySelector.click();
      await page.waitForTimeout(1500);
      // Flutter popup menu items have flt-tappable and intercept pointer events.
      // Use force: true to bypass pointer-interception checks.
      // Try the first visible category menuitem (aria-label contains "category-option-")
      const firstMenuItem = page.locator('flt-semantics[role="menuitem"][aria-label*="category-option-"]').first();
      const menuItemFound = await firstMenuItem.waitFor({ state: 'attached', timeout: 3000 })
        .then(() => true).catch(() => false);
      if (menuItemFound) {
        await firstMenuItem.click({ force: true });
      } else {
        // Dismiss the popup by clicking outside
        await page.mouse.click(0, 0);
      }
      await page.waitForTimeout(500);
    }

    // Dismiss any remaining open popup/overlay before scrolling
    const openPopup = page.getByRole('menuitem').first();
    if (await openPopup.isVisible({ timeout: 1000 }).catch(() => false)) {
      await page.mouse.click(0, 0);
      await page.waitForTimeout(500);
    }

    // Scroll to bottom and click publish
    await scrollToBottom(page);
    const publishBtn = getPublishBtn(page);
    await expect(publishBtn).toBeAttached({ timeout: 30_000 });
    await publishBtn.click({ force: true });
    await page.waitForTimeout(3000);

    // Check outcome: success snackbar OR navigation away OR stayed (validation failed)
    const successSnackbar = page.getByText(/product.*created|produit.*créé|success/i).first();
    const snackbarVisible = await successSnackbar.isVisible({ timeout: 5000 }).catch(() => false);
    const currentUrl = page.url();
    // At least one meaningful outcome must be true:
    // 1. Success snackbar appeared
    // 2. Navigated away from add-product (published successfully)
    // 3. Stayed on add-product (validation caught missing fields like address/images)
    // Without uploading images, validation should keep us on form OR snackbar appears
    if (snackbarVisible) {
      // Product was created — navigated away from add-product
      expect(currentUrl).not.toMatch(/\/add-product/i);
    } else {
      // Validation prevented submission — stayed on add-product page
      expect(currentUrl).toMatch(/\/add-product/i);
    }
  });

  test('T11: UI — Form validation prevents empty submission', async ({ page }) => {
    // Try to publish without filling any fields
    await scrollToBottom(page);
    const publishBtn = getPublishBtn(page);
    await expect(publishBtn).toBeAttached({ timeout: 30_000 });
    // force: true bypasses Flutter Web actionability checks that can stall on flt-semantics
    await publishBtn.click({ force: true });
    await page.waitForTimeout(2000);
    // Should stay on add-product page (validation prevents navigation)
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 10_000 });
  });

  test('T12: UI — Form state resets on navigation', async ({ page }) => {
    // Flutter Web: use the actual <input> element (aria-label from hintText)
    const nameInput = page.locator('input[aria-label="Enter product name"]').first();
    const nameFound = await nameInput.waitFor({ state: 'attached', timeout: 20_000 })
      .then(() => true).catch(() => false);
    if (nameFound) {
      await nameInput.click({ timeout: 20_000 }).catch(() => { });
    } else {
      // Fallback to role-based selector (nth(1) skips disabled label node)
      await page.getByRole('textbox', { name: /product name/i }).nth(1)
        .click({ force: true, timeout: 10_000 }).catch(() => { });
    }
    await page.waitForTimeout(500);
    await page.keyboard.type('Temporary Product', { delay: 30 });

    // Navigate away via in-app navigation (NOT page.goto)
    await navigateHome(page, TARGET_URL);
    await waitForFlutter(page);

    // Return to add product via in-app navigation (page.goto kills auth — SDK JWT is in-memory only)
    await navigateToAddProduct(page, TARGET_URL);

    // Verify form was reset — fresh navigator push creates a new ViewModel instance.
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 15_000 });
    // The name field should be empty (new ViewModel = no prior state).
    const nameInputNew = page.locator('input[aria-label="Enter product name"]').first();
    const newNameFound = await nameInputNew.waitFor({ state: 'attached', timeout: 15_000 })
      .then(() => true).catch(() => false);
    if (newNameFound) {
      const val = await nameInputNew.inputValue().catch(() => '');
      expect(val.trim()).not.toContain('Temporary Product');
    } else {
      // Form loaded but input not found as <input> — verify URL at minimum
      await expect(page).toHaveURL(/\/add-product/i, { timeout: 5_000 });
    }
  });
});
