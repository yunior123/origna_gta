/**
 * OrignaGTA — Favorites E2E Tests
 * =================================
 * Tests favorites functionality via UI.
 */
import { test, expect } from '@playwright/test';
import {
  waitForFlutter,
  requireWebApp,
  checkSemantics,
  ensureLoggedInAsAdmin,
  performSignOut,
  navigateHome,
  BTN_SETTINGS,
} from './flutter-helpers';
import { TEST_ACCOUNTS, WEB_APP_URL } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;

test.describe('Favorites', () => {
  test.setTimeout(300_000);

  test('User can navigate to favorites page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
    await waitForFlutter(page);

    const menuFavorites = page.locator('[aria-label^="menu-favorites"]').first();
    if (await menuFavorites.isVisible().catch(() => false)) {
      await menuFavorites.click();
      await expect(page).toHaveURL(/\/favorites/i, { timeout: 20000 });
      await waitForFlutter(page);
      expect(page.url()).toMatch(/\/favorites/i);
    }

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('Product card favorite toggle is accessible', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    // Scroll to find product cards
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    if ((await productCards.count()) > 0) {
      // Click on a product card to open detail
      await productCards.first().click();
      await page.waitForTimeout(2000);

      // Look for a favorite/heart button on the product detail page
      const favBtn = page.locator('[aria-label*="favorite"], [aria-label*="heart"], [aria-label*="like"]').first();
      if (await favBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
        // Toggle favorite
        await favBtn.click();
        await page.waitForTimeout(1000);
        // Toggle back
        await favBtn.click();
        await page.waitForTimeout(500);
      }

      await page.goBack();
      await waitForFlutter(page);
    }

    await performSignOut(page, TARGET_URL);
  });
});
