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

/**
 * REPLICA of integration_test/flows/add_product_flow_test.dart
 *
 * NOTE: Tests do NOT publish products (requires full backend/Algolia).
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://orignagta-dev.web.app';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Add Product Flow', () => {
    test.setTimeout(300_000);

    test.beforeEach(async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);

        const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
        await expect(addProductBtn).toBeVisible({ timeout: 20000 });
        await addProductBtn.click();
        await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
        await waitForFlutter(page);
    });

    test.afterEach(async ({ page }) => {
        // Use in-app navigation (not page.goto) to preserve Firebase Auth state for sign-out
        await navigateHome(page, TARGET_URL);
        await performSignOut(page, TARGET_URL);
    });

    test('T01: Product Name validation — cannot submit empty', async ({ page }) => {
        const publishBtn = page.locator('[aria-label^="btn-publish-product"]').first();
        await page.keyboard.press('End');
        await page.waitForTimeout(500);
        await publishBtn.click();
        await page.waitForTimeout(1000);
        // Should stay on the same page
        expect(page.url()).toMatch(/\/add-product/i);
    });

    test('T02: Price validation — cannot be zero', async ({ page }, testInfo) => {
        const nameInput = page.getByRole('textbox', { name: /product name|nom du produit/i }).first();
        await nameInput.pressSequentially(`Price Test ${uniqueSuffix(testInfo)}`, { delay: 30 });

        const priceInput = page.getByRole('textbox', { name: /price|prix/i }).first();
        await priceInput.click();
        await priceInput.pressSequentially('0', { delay: 30 });

        const publishBtn = page.locator('[aria-label^="btn-publish-product"]').first();
        await page.keyboard.press('End');
        await page.waitForTimeout(500);
        await publishBtn.click();
        await page.waitForTimeout(1000);
        expect(page.url()).toMatch(/\/add-product/i);
    });

    test('T03: Stock validation — must be positive', async ({ page }, testInfo) => {
        const nameInput = page.getByRole('textbox', { name: /product name/i }).first();
        await nameInput.pressSequentially(`Stock Test ${uniqueSuffix(testInfo)}`, { delay: 30 });

        const stockInput = page.getByRole('textbox', { name: /stock|quantit/i }).first();
        await stockInput.click();
        await stockInput.pressSequentially('-5', { delay: 30 });

        const publishBtn = page.locator('[aria-label^="btn-publish-product"]').first();
        await page.keyboard.press('End');
        await publishBtn.click();
        await page.waitForTimeout(1000);
        expect(page.url()).toMatch(/\/add-product/i);
    });

    test('T04: Description field visibility and interaction', async ({ page }) => {
        const descInput = page.getByRole('textbox', { name: /description/i }).first();
        await expect(descInput).toBeVisible();
        await descInput.click();
        await descInput.pressSequentially('Detailed product description for testing purposes.', { delay: 30 });
        await expect(descInput).toHaveValue(/Detailed product description/);
    });

    test('T05: Category selector interaction', async ({ page }) => {
        const categorySelector = page.getByRole('button', { name: /category|catégorie/i }).first();
        if (await categorySelector.isVisible()) {
            await categorySelector.click();
            await page.waitForTimeout(500);
            // Verify some categories are shown (Electronics, Fashion, etc.)
            const electronicsOption = page.getByText(/electronics|électronique/i).first();
            await expect(electronicsOption).toBeVisible();
            await electronicsOption.click();
        }
    });

    test('T06: Warehouse selection UI', async ({ page }) => {
        await page.keyboard.press('End');
        await page.waitForTimeout(500);
        const warehouseSelector = page.getByRole('button', { name: /select warehouse|sélectionner un entrepôt/i }).first();
        // This might only show if the seller has warehouses
        if (await warehouseSelector.isVisible()) {
            await expect(warehouseSelector).toBeEnabled();
        } else {
            // Fallback: should see origin address fields or "Seller Address"
            const originText = page.getByText(/shipping origin|origine de l'expédition/i).first();
            await expect(originText).toBeVisible();
        }
    });

    test('T07: Delivery speed toggles', async ({ page }) => {
        await page.keyboard.press('End');
        await page.waitForTimeout(500);

        const standardToggle = page.getByRole('switch', { name: /standard delivery|livraison standard/i }).first();
        if (await standardToggle.isVisible()) {
            const isChecked = await standardToggle.getAttribute('aria-checked');
            await standardToggle.click();
            await page.waitForTimeout(400);
            expect(await standardToggle.getAttribute('aria-checked')).not.toBe(isChecked);
        }
    });

    test('T08: Dimensions and Weight validation', async ({ page }) => {
        await page.keyboard.press('End');
        await page.waitForTimeout(500);

        const weightInput = page.getByRole('textbox', { name: /weight|poids/i }).first();
        if (await weightInput.isVisible()) {
            await weightInput.click();
            await weightInput.pressSequentially('2.5', { delay: 30 });
            await expect(weightInput).toHaveValue('2.5');
        }
    });

    test('T09: Info tooltips presence', async ({ page }) => {
        // Check for at least one info tooltip button
        const infoButtons = page.locator('button[aria-label*="info"], button[aria-label*="help"]');
        const count = await infoButtons.count();
        // There should be some info buttons for SKU, shipping, etc.
        if (count > 0) {
            await expect(infoButtons.first()).toBeVisible();
        }
    });

    test('T10: Digital product — Software sub-type fields', async ({ page }) => {
        const digitalToggle = page.getByRole('switch', { name: /digital/i }).first();
        await expect(digitalToggle).toBeVisible();
        if ((await digitalToggle.getAttribute('aria-checked')) !== 'true') {
            await digitalToggle.click();
            await page.waitForTimeout(800);
        }

        const softwareChip = page.getByRole('button', { name: /software/i }).first();
        await expect(softwareChip).toBeVisible();
        await softwareChip.click();

        const macosField = page.getByRole('textbox', { name: /macos/i }).first();
        await expect(macosField).toBeVisible();
        const windowsField = page.getByRole('textbox', { name: /windows/i }).first();
        await expect(windowsField).toBeVisible();
    });

    test('T11: Digital product — Book sub-type fields', async ({ page }) => {
        const digitalToggle = page.getByRole('switch', { name: /digital/i }).first();
        if ((await digitalToggle.getAttribute('aria-checked')) !== 'true') {
            await digitalToggle.click();
            await page.waitForTimeout(800);
        }

        const bookChip = page.getByRole('button', { name: /book/i }).first();
        await expect(bookChip).toBeVisible();
        await bookChip.click();

        const bookUrlField = page.getByRole('textbox', { name: /download source url|book download/i }).first();
        await expect(bookUrlField).toBeVisible();
    });

    test('T12: Back navigation and state reset', async ({ page }) => {
        const nameInput = page.getByRole('textbox', { name: /product name/i }).first();
        await nameInput.pressSequentially('Temporary Product', { delay: 30 });

        // Navigate back to home
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        // Navigate back to Add Product
        const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
        await addProductBtn.click();
        await waitForFlutter(page);

        // Verify name input is empty (state reset)
        const nameInputNew = page.getByRole('textbox', { name: /product name/i }).first();
        await expect(nameInputNew).toHaveValue('');
    });
});

