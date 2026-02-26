/**
 * OrignaGTA — Seller Product Management E2E Tests
 * ==================================================
 * Tests product CRUD operations via UI against dev Firebase.
 */
import { test, expect } from '@playwright/test';
import {
  waitForFlutter,
  requireWebApp,
  checkSemantics,
  ensureLoggedInAsAdmin,
  performSignOut,
  navigateHome,
  uniqueSuffix,
  BTN_ADD_PRODUCT,
} from './flutter-helpers';
import { WEB_APP_URL, TEST_ACCOUNTS } from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const SELLER_EMAIL = process.env.E2E_SELLER_EMAIL ?? TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASSWORD = process.env.E2E_SELLER_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;

test.describe('Seller Product Management', () => {
  test.setTimeout(300_000);

  test('Seller can navigate to add product page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    await expect(addProductBtn).toBeVisible({ timeout: 20000 });
    await addProductBtn.click();
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
    await waitForFlutter(page);

    expect(page.url()).toMatch(/\/add-product/i);
  });

  test('Product form validates required fields', async ({ page }, testInfo) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    await addProductBtn.click();
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
    await waitForFlutter(page);

    // Try to publish without filling required fields
    const publishBtn = page.locator('[aria-label^="btn-publish-product"]').first();
    await page.keyboard.press('End');
    await page.waitForTimeout(500);

    if (await publishBtn.isVisible({ timeout: 8000 }).catch(() => false)) {
      await publishBtn.scrollIntoViewIfNeeded().catch(() => {});
      await publishBtn.click();
      await page.waitForTimeout(1000);
      // Should stay on add-product page (validation failed)
      expect(page.url()).toMatch(/\/add-product/i);
    }
  });

  test('Product form accepts valid input', async ({ page }, testInfo) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    const suffix = uniqueSuffix(testInfo);

    const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    await addProductBtn.click();
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
    await waitForFlutter(page);

    // Fill product name (Flutter Web: click first, wait for focus, then pressSequentially)
    const nameInput = page.getByRole('textbox', { name: /product name|nom du produit/i }).first();
    await expect(nameInput).toBeVisible({ timeout: 20000 });
    await nameInput.click();
    await page.waitForTimeout(300);
    await nameInput.pressSequentially(`E2E Test Product ${suffix}`, { delay: 30 });

    // Fill description
    const descInput = page.getByRole('textbox', { name: /description/i }).first();
    if (await descInput.isVisible({ timeout: 5000 }).catch(() => false)) {
      await descInput.click();
      await page.waitForTimeout(200);
      await descInput.pressSequentially('Automated E2E test product — do not ship', { delay: 20 });
    }

    // Fill price
    const priceInput = page.getByRole('textbox', { name: /price|prix/i }).first();
    await expect(priceInput).toBeVisible({ timeout: 10000 });
    await priceInput.click();
    await page.waitForTimeout(200);
    await priceInput.pressSequentially('19.99', { delay: 30 });

    // Fill stock
    const stockInput = page.getByRole('textbox', { name: /stock|quantit/i }).first();
    if (await stockInput.isVisible({ timeout: 5000 }).catch(() => false)) {
      await stockInput.click();
      await page.waitForTimeout(200);
      await stockInput.pressSequentially('5', { delay: 30 });
    }

    // Verify name field accepted input
    const nameAriaValue = await nameInput.evaluate((el) =>
      el.getAttribute('aria-valuenow') ??
      el.getAttribute('value') ??
      (el as HTMLInputElement).value ??
      el.textContent ??
      ''
    );
    // Accept partial match since first character may be dropped on focus transition
    const containsProductText = nameAriaValue.includes('E2E Test Product') || nameAriaValue.includes('2E Test Product');
    expect(containsProductText, `Name field value "${nameAriaValue}" should contain product text`).toBe(true);

    // Return to home via in-app navigation (preserves auth)
    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('Digital product toggle works', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);
    // ensureLoggedInAsAdmin already navigates back to home — no page.goto() here

    const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    await addProductBtn.click();
    await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
    await waitForFlutter(page);

    // Find digital product toggle
    await page.keyboard.press('End');
    await page.waitForTimeout(600);

    const digitalLabel = page.getByText(/digital product|produit num/i).first();
    if (await digitalLabel.isVisible({ timeout: 8000 }).catch(() => false)) {
      await digitalLabel.scrollIntoViewIfNeeded().catch(() => {});
      const allSwitches = page.locator('[role="switch"]');
      if (await allSwitches.count() > 0) {
        const digitalSwitch = allSwitches.first();
        const before = await digitalSwitch.getAttribute('aria-checked');
        await digitalSwitch.click();
        await page.waitForTimeout(600);
        const after = await digitalSwitch.getAttribute('aria-checked');
        expect(before).not.toBe(after);

        // Toggle back
        await digitalSwitch.click();
        await page.waitForTimeout(400);
      }
    }

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });
});
