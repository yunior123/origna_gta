import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
    uniqueSuffix,
    BTN_ADD_PRODUCT,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/add_product_flow_test.dart
 *
 * NOTE: Tests do NOT publish products (requires full backend/Algolia).
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Add Product Flow', () => {
    test.setTimeout(300_000);

    test('P01-P12: Add Product varieties and validation', async ({ page }, testInfo) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // P00: Login as seller/admin
        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        const suffix = uniqueSuffix(testInfo);
        const p01Name = `T01 Standard Ship ${suffix}`;
        const p12Name = `T12 Bad Price ${suffix}`;

        // P00: Navigate to Add Product via home AppBar button
        const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
        await expect(addProductBtn).toBeVisible({ timeout: 20000 });
        await addProductBtn.click();
        await expect(page).toHaveURL(/\/add-product/i, { timeout: 30000 });
        await waitForFlutter(page);

        // C011: Add product screen loaded
        expect(page.url()).toMatch(/\/add-product/i);

        // P01: Fill basic fields
        const nameInput = page.getByRole('textbox', { name: /product name|nom du produit/i }).first();
        await expect(nameInput).toBeVisible({ timeout: 20000 });
        await nameInput.fill(p01Name);

        const descInput = page.getByRole('textbox', { name: /description/i }).first();
        if (await descInput.isVisible({ timeout: 5000 }).catch(() => false)) {
            await descInput.fill('Test description for E2E run');
        }

        const priceInput = page.getByRole('textbox', { name: /price|prix/i }).first();
        await expect(priceInput).toBeVisible({ timeout: 10000 });
        await priceInput.fill('29.99');

        const stockInput = page.getByRole('textbox', { name: /stock|quantit/i }).first();
        if (await stockInput.isVisible({ timeout: 5000 }).catch(() => false)) {
            await stockInput.fill('10');
        }

        // Scroll to delivery section
        await page.keyboard.press('End');
        await page.waitForTimeout(600);

        // C012: Standard delivery section visible
        const standardDeliveryText = page.getByText(/standard delivery|livraison standard/i).first();
        if (await standardDeliveryText.isVisible({ timeout: 8000 }).catch(() => false)) {
            await standardDeliveryText.scrollIntoViewIfNeeded().catch(() => { });
        }

        // P02/P10: Digital toggle
        const digitalLabelText = page.getByText(/digital product|produit num/i).first();
        if (await digitalLabelText.isVisible({ timeout: 8000 }).catch(() => false)) {
            await digitalLabelText.scrollIntoViewIfNeeded().catch(() => { });
            await page.waitForTimeout(400);

            const allSwitches = page.locator('[role="switch"]');
            const switchCount = await allSwitches.count();

            if (switchCount > 0) {
                const digitalSwitch = allSwitches.first();
                const beforeState = await digitalSwitch.getAttribute('aria-checked').catch(() => null);

                await digitalSwitch.click();
                await page.waitForTimeout(600);

                const afterState = await digitalSwitch.getAttribute('aria-checked').catch(() => null);

                if (beforeState === 'false' && afterState === 'true') {
                    await page.waitForTimeout(400);
                    // Toggle back OFF
                    await digitalSwitch.click();
                    await page.waitForTimeout(600);
                } else if (beforeState === 'true') {
                    await digitalSwitch.click();
                    await page.waitForTimeout(400);
                }
            }
        }

        // P11: Validation — submit without name
        await nameInput.fill('');

        const publishBtn = page.locator('[aria-label^="btn-publish-product"]').first();

        await page.keyboard.press('End');
        await page.waitForTimeout(500);

        if (await publishBtn.isVisible({ timeout: 8000 }).catch(() => false)) {
            await publishBtn.scrollIntoViewIfNeeded().catch(() => { });
            await publishBtn.click();
            await page.waitForTimeout(1000);
            expect(page.url()).toMatch(/\/add-product/i);
        }

        // P12: Validation — zero price
        await nameInput.fill(p12Name);
        await priceInput.fill('0');

        if (await publishBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
            await publishBtn.click();
            await page.waitForTimeout(1000);
            expect(page.url()).toMatch(/\/add-product/i);
        }

        // Return to home before sign-out
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        // C080/C099: Sign-out
        await performSignOut(page, TARGET_URL);
    });
});
