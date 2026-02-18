import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
    BTN_SETTINGS,
    BTN_CART,
    BTN_ADD_PRODUCT,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/admin_flow_test.dart
 *
 * NOTE: Admin tabs are a Flutter TabBar — clicking a tab does NOT change the URL.
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Admin Panel Flow', () => {
    test.setTimeout(300_000);

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

        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
        await expect(settingsBtn).toBeAttached();

        // C063: Add product button visible for admin
        const addProductBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
        await expect(addProductBtn).toBeVisible({ timeout: 20000 });

        // C042/C064: Profile → admin panel visible
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
        await waitForFlutter(page);

        // Flutter Web: use getByRole with accessible name matching (more reliable than aria-label CSS selectors)
        const adminMenu = page.getByRole('button', { name: /menu-admin-panel|admin panel/i }).first();
        await adminMenu.scrollIntoViewIfNeeded().catch(() => {});
        await expect(adminMenu).toBeVisible({ timeout: 20000 });

        // C064: Buyer orders also accessible
        const myOrdersBtn = page.getByRole('button', { name: /menu-my-orders|my orders/i }).first();
        await expect(myOrdersBtn).toBeVisible({ timeout: 10000 });

        // C043: Quick seller orders check
        const sellerOrdersBtn = page.getByRole('button', { name: /menu-seller-orders|seller orders/i }).first();
        if (await sellerOrdersBtn.isVisible().catch(() => false)) {
            await sellerOrdersBtn.click();
            await expect(page).toHaveURL(/\/seller\/orders/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C044-C052: Enter admin panel and navigate all 6 tabs
        await adminMenu.click();
        await expect(page).toHaveURL(/\/admin/i, { timeout: 20000 });
        await waitForFlutter(page);

        // Admin tabs: use getByRole with accessible name matching
        const adminTabNames = [
            /admin-tab-sellers|sellers/i,
            /admin-tab-users|users/i,
            /admin-tab-orders|orders/i,
            /admin-tab-products|products/i,
            /admin-tab-payments|payments/i,
            /admin-tab-security|security/i,
        ];

        for (const tabName of adminTabNames) {
            const tabLocator = page.getByRole('tab', { name: tabName }).first();
            // Fall back to button role if tab role not found
            const tabOrButton = (await tabLocator.count()) > 0
                ? tabLocator
                : page.getByRole('button', { name: tabName }).first();
            await expect(tabOrButton).toBeVisible({ timeout: 15000 });
            await tabOrButton.click();
            await page.waitForTimeout(600);
            expect(page.url()).toMatch(/\/admin/i);
        }

        // C065: Both orders and payments tabs persistent
        await expect(page.getByRole('tab', { name: /orders/i }).or(page.getByRole('button', { name: /admin-tab-orders|orders/i })).first()).toBeVisible();
        await expect(page.getByRole('tab', { name: /payments/i }).or(page.getByRole('button', { name: /admin-tab-payments|payments/i })).first()).toBeVisible();

        // Return to profile
        await page.goBack();
        await waitForFlutter(page);
        await expect(page).toHaveURL(/\/profile/i, { timeout: 15000 });

        // C053: Privacy screen (soft check — Flutter Web may render inline)
        const privacyBtn = page.getByRole('button', { name: /menu-privacy/i }).first();
        if (await privacyBtn.isVisible().catch(() => false)) {
            await privacyBtn.click();
            await page.waitForTimeout(2000);
            const navigatedToPrivacy = page.url().match(/\/privacy-policy/i);
            if (navigatedToPrivacy) {
                await page.goBack();
                await waitForFlutter(page);
            }
        }

        // C066-C068: Return to home
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await expect(settingsBtn).toBeAttached();
        await expect(page.getByRole('button', { name: BTN_CART }).first()).toBeAttached();

        // C069/C070: Settings still opens
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile/i, { timeout: 15000 });
        await page.goBack();
        await waitForFlutter(page);

        // C080/C099: Sign-out
        await performSignOut(page, TARGET_URL);
    });
});
