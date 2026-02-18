import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/admin_flow_test.dart
 *
 * Selector mapping:
 *   home_settings_button       → getByRole('button', { name: /settings/i })
 *   home_add_product_button    → getByRole('button', { name: /add product/i })
 *   profile_admin_panel_button → locator('[aria-label="menu-admin-panel"]')
 *   profile_seller_orders_btn  → locator('[aria-label="menu-seller-orders"]')
 *   profile_my_orders_button   → locator('[aria-label="menu-my-orders"]')
 *   profile_privacy_button     → locator('[aria-label="menu-privacy"]')
 *   admin-tab-sellers          → locator('[aria-label="admin-tab-sellers"]')  (semanticLabel in admin_panel_screen.dart)
 *   admin-tab-users            → locator('[aria-label="admin-tab-users"]')
 *   admin-tab-orders           → locator('[aria-label="admin-tab-orders"]')
 *   admin-tab-products         → locator('[aria-label="admin-tab-products"]')
 *   admin-tab-payments         → locator('[aria-label="admin-tab-payments"]')
 *   admin-tab-security         → locator('[aria-label="admin-tab-security"]')
 *   btn-sign-out               → locator('[aria-label="btn-sign-out"]')
 *
 * NOTE: Admin tabs are a Flutter TabBar — clicking a tab does NOT change the URL.
 *       Only assert tab element visibility and stability, not URL changes.
 *
 * Routes:
 *   adminPanel    = '/admin'
 *   privacyPolicy = '/privacy-policy'
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? '960227Y#y';

test.describe('PW IT Replica — Admin Panel Flow', () => {
    test.setTimeout(300_000); // 5 min; runs in parallel

    test('Navigate through Admin Panel tabs', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // D01: Login as admin
        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        const settingsBtn = page.getByRole('button', { name: /settings/i }).first();
        await expect(settingsBtn).toBeAttached();

        // C063: Add product button visible for admin
        const addProductBtn = page.getByRole('button', { name: /add product/i }).first();
        await expect(addProductBtn).toBeVisible({ timeout: 20000 });

        // C042/C064: Profile → admin panel visible + buyer orders still accessible
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        const adminMenu = page.locator('[aria-label="menu-admin-panel"]').first();
        await expect(adminMenu).toBeVisible({ timeout: 20000 });

        // C064: Buyer orders also accessible
        const myOrdersBtn = page.locator('[aria-label="menu-my-orders"]').first();
        await expect(myOrdersBtn).toBeVisible({ timeout: 10000 });

        // C043: Quick seller orders check (if visible)
        const sellerOrdersBtn = page.locator('[aria-label="menu-seller-orders"]').first();
        if (await sellerOrdersBtn.isVisible().catch(() => false)) {
            await sellerOrdersBtn.click();
            await expect(page).toHaveURL(/\/seller\/orders(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C044-C052: Enter admin panel and navigate all 6 tabs
        await adminMenu.click();
        await expect(page).toHaveURL(/\/admin(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // All 6 tabs defined in admin_panel_screen.dart with semanticLabel
        const adminTabs = [
            'admin-tab-sellers',
            'admin-tab-users',
            'admin-tab-orders',
            'admin-tab-products',
            'admin-tab-payments',
            'admin-tab-security',
        ];

        for (const tabLabel of adminTabs) {
            const tabLocator = page.locator(`[aria-label="${tabLabel}"]`).first();
            // Tab must be visible (C046-C051)
            await expect(tabLocator).toBeVisible({ timeout: 15000 });
            // Click and verify app remains stable — tabs don't change URL in Flutter TabBar
            await tabLocator.click();
            await page.waitForTimeout(600);
            // App must stay on /admin (tabs are in-page navigation only)
            expect(page.url()).toMatch(/\/admin(?:\b|\/|\?|#|$)/i);
        }

        // C065: Both orders and payments tabs persistent
        await expect(page.locator('[aria-label="admin-tab-orders"]').first()).toBeVisible();
        await expect(page.locator('[aria-label="admin-tab-payments"]').first()).toBeVisible();

        // Return to profile
        await page.goBack();
        await waitForFlutter(page);
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 15000 });

        // C053: Privacy screen (menu-privacy → /privacy-policy)
        const privacyBtn = page.locator('[aria-label="menu-privacy"]').first();
        if (await privacyBtn.isVisible().catch(() => false)) {
            await privacyBtn.click();
            await expect(page).toHaveURL(/\/privacy-policy(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C066/C067/C068: Return to home — cart and settings still available
        await page.goBack();
        await waitForFlutter(page);
        await expect(settingsBtn).toBeAttached();
        await expect(page.getByRole('button', { name: /cart|shopping/i }).first()).toBeAttached();

        // C069/C070: Settings still opens at end of run
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 15000 });
        await page.goBack();
        await waitForFlutter(page);

        // C080/C099: Sign-out
        await performSignOut(page, TARGET_URL);
    });
});
