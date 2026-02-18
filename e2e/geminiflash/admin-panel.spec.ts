import { test, expect } from '@playwright/test';
import { waitForFlutter, requireWebApp, checkSemantics, ensureLoggedInAsAdmin } from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Admin Panel Flow', () => {
    test.setTimeout(600_000);

    test('Navigate through Admin Panel tabs', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(120_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);

        // Standardized Profile Navigation
        const profileBtn = page.getByLabel('menu-profile').first();
        await expect(profileBtn).toBeVisible({ timeout: 30000 });
        await profileBtn.click();
        await page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // Enter Admin Panel
        const adminMenu = page.getByLabel('menu-admin-panel').first();
        await expect(adminMenu).toBeVisible({ timeout: 30000 });
        await adminMenu.click();
        await page.waitForURL(/\/admin(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // Check tabs
        const tabs = [
            { label: 'admin-tab-sellers', url: /.*sellers.*/ },
            { label: 'admin-tab-users', url: /.*users.*/ },
            { label: 'admin-tab-orders', url: /.*orders.*/ },
            { label: 'admin-tab-products', url: /.*products.*/ },
        ];

        for (const tab of tabs) {
            const tabLocator = page.getByLabel(tab.label).first();
            await expect(tabLocator).toBeVisible({ timeout: 15000 });
            await tabLocator.click();
            await page.waitForTimeout(500); // Wait for tab animation
        }

        await page.goBack(); // Back to Profile
        await waitForFlutter(page);
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i);
    });
});
