import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/seller_flow_test.dart
 *
 * Selector mapping:
 *   home_add_product_button         → getByRole('button', { name: /add product/i }) (tooltip="Add product")
 *   home_settings_button            → getByRole('button', { name: /settings/i })
 *   profile_seller_orders_button    → locator('[aria-label="menu-seller-orders"]')
 *   profile_seller_dashboard_button → locator('[aria-label="menu-seller-dashboard"]')
 *   profile_become_seller_button    → locator('[aria-label="menu-become-seller"]')
 *   profile_my_orders_button        → locator('[aria-label="menu-my-orders"]')
 *   btn-sign-out                    → locator('[aria-label="btn-sign-out"]')
 *
 * Routes (from AppRoutes):
 *   sellerOrders        = '/seller/orders'
 *   sellerRegistration  = '/seller/register'  ← seller_dashboard navigates here
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const SELLER_EMAIL = process.env.E2E_SELLER_EMAIL ?? 'seller1@test.origna.ca';
const SELLER_PASSWORD = process.env.E2E_SELLER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Seller Flow', () => {
    test.setTimeout(300_000); // 5 min; runs in parallel

    test('Complete Seller Journey', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // C01: Login as seller
        await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, SELLER_PASSWORD);
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        const settingsBtn = page.getByRole('button', { name: /settings/i }).first();
        await expect(settingsBtn).toBeAttached();

        // C034/C035: Add product button visible and navigates to /add-product
        const addProductBtn = page.getByRole('button', { name: /add product/i }).first();
        await expect(addProductBtn).toBeVisible({ timeout: 20000 });
        await addProductBtn.click();
        await expect(page).toHaveURL(/\/add-product(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await page.goBack();
        await waitForFlutter(page);

        // C036-C040: Profile → seller tools
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // C038: become-seller button must NOT be visible for a seller
        const becomeSellerBtn = page.locator('[aria-label="menu-become-seller"]').first();
        const becomeSellerVisible = await becomeSellerBtn.isVisible({ timeout: 3000 }).catch(() => false);
        expect(becomeSellerVisible).toBeFalsy();

        // C037/C039: Seller dashboard navigates to /seller/register (AppRoutes.sellerRegistration)
        const dashboardBtn = page.locator('[aria-label="menu-seller-dashboard"]').first();
        if (await dashboardBtn.isVisible().catch(() => false)) {
            await dashboardBtn.click();
            await expect(page).toHaveURL(/\/seller\/register(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C040: Seller orders navigates to /seller/orders
        const ordersBtn = page.locator('[aria-label="menu-seller-orders"]').first();
        if (await ordersBtn.isVisible().catch(() => false)) {
            await ordersBtn.click();
            await expect(page).toHaveURL(/\/seller\/orders(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C041/C062: Return to home; buyer-side cart still accessible
        await page.goBack();
        await waitForFlutter(page);
        await expect(settingsBtn).toBeAttached();

        const cartBtn = page.getByRole('button', { name: /cart|shopping/i }).first();
        await expect(cartBtn).toBeAttached();

        // C080/C099: Sign-out
        await performSignOut(page, TARGET_URL);
    });
});
