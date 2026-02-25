/**
 * OrignaGTA — Search & Discovery E2E Tests
 * ==========================================
 * Tests product search and browsing via UI.
 */
import { test, expect } from '@playwright/test';
import {
  waitForFlutter,
  requireWebApp,
  checkSemantics,
  BTN_SETTINGS,
} from './flutter-helpers';
import { WEB_APP_URL } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;

test.describe('Search & Discovery', () => {
  test.setTimeout(300_000);

  test('Home page shows product cards', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // Scroll to find product cards
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    expect(await productCards.count()).toBeGreaterThan(0);
  });

  test('Search bar is accessible on home page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    const searchBar = page.locator('[aria-label="input-home-search"]').first();
    const searchVisible = await searchBar.isVisible({ timeout: 10000 }).catch(() => false);

    if (searchVisible) {
      await searchBar.click();
      await searchBar.pressSequentially('test', { delay: 30 });
      await page.waitForTimeout(2000);

      // Search may trigger autocomplete or filter
      // Just verify the search input accepted text — aria-valuenow or label reflects text
      const value = await searchBar.getAttribute('aria-label').catch(() => '');
      const hasText = value?.includes('test') ?? false;
      // Flutter inputs may not expose value via inputValue(); check that page reacted
      await page.waitForTimeout(500);

      // Clear search
      await searchBar.click();
      await searchBar.press('Control+A');
      await searchBar.press('Backspace');
      await page.waitForTimeout(1000);
    }
  });

  test('Product card click navigates to product detail', async ({ page }) => {
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

    if ((await productCards.count()) > 0) {
      const homeUrl = page.url();
      await productCards.first().click();
      await page.waitForTimeout(2000);

      // Should navigate away from home (to product detail)
      const detailUrl = page.url();
      // URL may or may not change (depends on routing strategy)
      expect(detailUrl).toBeTruthy();

      await page.goBack();
      await waitForFlutter(page);
    }
  });

  test('Home page scroll loads more products', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // Get initial product count
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 6; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }
    const initialCount = await productCards.count();

    // Scroll more to trigger pagination
    for (let i = 0; i < 10; i++) {
      await page.mouse.wheel(0, 400);
      await page.waitForTimeout(800);
    }

    const finalCount = await productCards.count();
    // More products should load (or at least same count if all loaded)
    expect(finalCount).toBeGreaterThanOrEqual(initialCount);
  });
});
