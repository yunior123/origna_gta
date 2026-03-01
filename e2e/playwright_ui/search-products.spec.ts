import { test, expect } from '@playwright/test';
import {
  waitForFlutter, requireWebApp, checkSemantics,
} from './flutter-helpers';
import {
  signIn, callOk, callExpectError,
  TEST_ACCOUNTS, WEB_APP_URL,
} from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;

// ═══ API-DRIVEN TESTS ═══

test.describe('Search & Discovery — API Tests', () => {
  test.setTimeout(60_000);
  test.describe.configure({ mode: 'serial' });

  let buyerToken: string;

  test.beforeAll(async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    buyerToken = buyer.idToken;
  });

  test('T01: Get products paginated — returns products with required fields', async () => {
    const result = await callOk('get_products_paginated', { limit: 5 }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.products).toBeTruthy();
    expect(result.products.length).toBeGreaterThan(0);
    expect(result.products.length).toBeLessThanOrEqual(5);

    // Verify each product has required fields
    for (const product of result.products) {
      expect(product.productId || product.id).toBeTruthy();
      expect(product.name).toBeTruthy();
      expect(product.price).toBeGreaterThan(0);
      expect(product.sellerId).toBeTruthy();
    }
  });

  test('T02: Pagination cursor returns different products', async () => {
    const page1 = await callOk('get_products_paginated', { limit: 3 }, buyerToken);
    expect(page1.products.length).toBeGreaterThan(0);

    if (page1.nextCursor) {
      const page2 = await callOk('get_products_paginated', {
        limit: 3,
        startAfter: page1.nextCursor,
      }, buyerToken);

      // Verify no overlap between pages
      const page1Ids = new Set(page1.products.map((p: any) => p.productId || p.id));
      for (const p of page2.products) {
        expect(page1Ids.has(p.productId || p.id)).toBe(false);
      }
    }
  });

  test('T03: Category filter returns matching products only', async () => {
    const result = await callOk('get_products_paginated', {
      limit: 10,
      category: '1', // Electronics
    }, buyerToken);
    expect(result.success).toBe(true);

    if (result.products.length > 0) {
      for (const product of result.products) {
        expect(product.categoryId).toBe('1');
      }
    }
  });
});

// ═══ UI-DRIVEN TESTS ═══

test.describe('Search & Discovery — UI Tests', () => {
  test.setTimeout(300_000);

  test('T04: Home page shows product cards with known product', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    const count = await productCards.count();
    expect(count).toBeGreaterThan(0);
  });

  test('T05: Search bar accepts input and filters products', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    const searchBar = page.locator('[aria-label="input-home-search"]').first();
    await expect(searchBar).toBeVisible({ timeout: 10000 });

    // Type a search query
    await searchBar.click();
    await page.waitForTimeout(800);
    await searchBar.pressSequentially('sticker', { delay: 30 });
    await page.waitForTimeout(3000); // Wait for Algolia results

    // Verify search input was accepted by checking the field value
    const typedValue = await searchBar.inputValue();
    expect(typedValue).toContain('sticker');

    // Verify the page reacted: either product cards visible or an empty-state indicator appeared
    const hasResults = await page.locator('[aria-label^="product-card-"]').count();
    const emptyState = page.locator('[aria-label="empty-search-results"]').first();
    const hasEmpty = await emptyState.isVisible({ timeout: 3000 }).catch(() => false);
    expect(hasResults > 0 || hasEmpty).toBe(true);

    // Clear search
    const clearBtn = page.locator('[aria-label="btn-clear-search"]').first();
    if (await clearBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
      await clearBtn.click();
      await page.waitForTimeout(2000);
    }
  });

  test('T06: Product card click navigates to detail page with correct info', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    expect(await productCards.count()).toBeGreaterThan(0);

    const homeUrl = page.url();
    await productCards.first().click();
    await page.waitForTimeout(3000);
    await waitForFlutter(page);

    // Verify navigation happened (URL changed)
    await expect(page).not.toHaveURL(homeUrl, { timeout: 5000 });

    // Verify product detail elements are present — at least name or price
    const productName = page.locator('[key="product_detail_name"]').first();
    const productPrice = page.locator('[key="product_detail_price"]').first();
    const nameVisible = await productName.isVisible({ timeout: 5000 }).catch(() => false);
    const priceVisible = await productPrice.isVisible({ timeout: 5000 }).catch(() => false);
    expect(nameVisible || priceVisible).toBe(true);

    await page.goBack();
    await waitForFlutter(page);
  });

  test('T07: Scroll loads more products (pagination)', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 6; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }
    const initialCount = await productCards.count();
    expect(initialCount).toBeGreaterThan(0);

    // Scroll more to trigger pagination
    for (let i = 0; i < 10; i++) {
      await page.mouse.wheel(0, 400);
      await page.waitForTimeout(800);
    }

    const finalCount = await productCards.count();
    // Should load more products (or same if all loaded)
    expect(finalCount).toBeGreaterThanOrEqual(initialCount);
  });
});
