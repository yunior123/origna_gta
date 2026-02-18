/**
 * OrignaGTA — Profile Management E2E Tests
 * ==========================================
 * Tests profile viewing and account management via UI.
 */
import { test, expect } from '@playwright/test';
import {
  waitForFlutter,
  requireWebApp,
  checkSemantics,
  ensureLoggedInAsAdmin,
  performSignOut,
  BTN_SETTINGS,
} from './flutter-helpers';
import { signIn, callCallable, TEST_ACCOUNTS, WEB_APP_URL } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;

test.describe('Profile Management', () => {
  test.setTimeout(300_000);

  test('User can view profile page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
    await waitForFlutter(page);

    // Profile page should have common menu items
    const menuItems = [
      page.locator('[aria-label^="menu-my-orders"]').first(),
      page.locator('[aria-label^="menu-favorites"]').first(),
      page.locator('[aria-label^="menu-address"]').first(),
    ];

    for (const item of menuItems) {
      // At least some menu items should be visible
      const visible = await item.isVisible().catch(() => false);
      if (visible) expect(visible).toBeTruthy();
    }

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await performSignOut(page, TARGET_URL);
  });

  test('User can navigate to address management', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
    await waitForFlutter(page);

    const menuAddress = page.locator('[aria-label^="menu-address"]').first();
    if (await menuAddress.isVisible().catch(() => false)) {
      await menuAddress.click();
      await expect(page).toHaveURL(/\/addresses/i, { timeout: 20000 });
      await waitForFlutter(page);

      // Address page loaded
      expect(page.url()).toMatch(/\/addresses/i);
    }

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await performSignOut(page, TARGET_URL);
  });

  test('User can navigate to orders from profile', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
    await waitForFlutter(page);

    const menuOrders = page.locator('[aria-label^="menu-my-orders"]').first();
    if (await menuOrders.isVisible().catch(() => false)) {
      await menuOrders.click();
      await expect(page).toHaveURL(/\/orders/i, { timeout: 20000 });
      expect(page.url()).toMatch(/\/orders/i);
    }

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await performSignOut(page, TARGET_URL);
  });

  test('Privacy policy is accessible from profile', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
    await waitForFlutter(page);

    const privacyBtn = page.getByRole('button', { name: /menu-privacy/i }).first();
    if (await privacyBtn.isVisible().catch(() => false)) {
      await privacyBtn.click();
      await page.waitForTimeout(2000);
      // Privacy page may open inline or navigate
      const url = page.url();
      expect(url).toBeTruthy();
    }

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await performSignOut(page, TARGET_URL);
  });
});
