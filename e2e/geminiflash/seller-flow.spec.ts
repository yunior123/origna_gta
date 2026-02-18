import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const SELLER_EMAIL = process.env.E2E_SELLER_EMAIL ?? 'seller1@test.origna.ca';
const SELLER_PASSWORD = process.env.E2E_SELLER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Seller Flow', () => {
    test.setTimeout(600_000);

    test('Complete Seller Journey', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(120_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);

        // Home Add Product accessibility check
        const sellerAddBtn = page.getByLabel('menu-add-product').first();
        await expect(sellerAddBtn).toBeVisible({ timeout: 30000 });

        // Standardized Profile Navigation
        const profileBtn = page.getByLabel('menu-profile').first();
        await expect(profileBtn).toBeVisible({ timeout: 30000 });
        await profileBtn.click();
        await page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        const dashboardBtn = page.getByLabel('profile_seller_dashboard_button').first();
        const ordersBtn = page.getByLabel('profile_seller_orders_button').first();

        if (await dashboardBtn.isVisible()) {
            await dashboardBtn.click();
            await page.waitForURL(/\/dashboard(?:\b|\/|\?|#|$)/i);
            await page.goBack();
            await waitForFlutter(page);
        }

        if (await ordersBtn.isVisible()) {
            await ordersBtn.click();
            await page.waitForURL(/\/seller-orders(?:\b|\/|\?|#|$)/i);
            await page.goBack();
            await waitForFlutter(page);
        }

        await page.goBack(); // Back Home
        await waitForFlutter(page);
    });
});
