import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    uniqueSuffix
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Add Product Flow', () => {
    test.setTimeout(600_000);

    test('P01-P12: Add Product varieties and validation', async ({ page }, testInfo) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(120_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);


        const suffix = uniqueSuffix(testInfo);
        const p01Name = `T01 Standard Ship ${suffix}`;

        // Navigate to Add Product (Direct from Home)
        const addProductBtn = page.getByLabel('menu-add-product').first();
        await expect(addProductBtn).toBeVisible({ timeout: 30000 });
        await addProductBtn.click();
        await page.waitForURL(/\/add-product(?:\b|\/|\?|#|$)/i, { timeout: 30000 });
        await waitForFlutter(page);

        // P01: Standard Physical Product
        const nameInput = page.getByLabel('product-name-field').first();
        await nameInput.fill(p01Name);

        const priceInput = page.getByLabel('product-price-field').first();
        await priceInput.fill('29.99');

        // Digital Toggle
        const digitalToggle = page.getByLabel('addproduct_digital_toggle').first();
        await digitalToggle.click();
        await page.waitForTimeout(500);

        const digitalBanner = page.getByLabel('addproduct_digital_info_banner').first();
        await expect(digitalBanner).toBeVisible();

        // Validation (Empty price)
        await digitalToggle.click(); // Back to physical
        await priceInput.clear();
        const publishBtn = page.getByRole('button', { name: /publish|publier/i }).first();
        await publishBtn.click();

        // Should still be on Add Product
        await expect(page).toHaveURL(/\/add-product(?:\b|\/|\?|#|$)/i);

        await page.goBack();
        await waitForFlutter(page);
        await expect(page).toHaveURL(`${TARGET_URL}/`);
    });
});
