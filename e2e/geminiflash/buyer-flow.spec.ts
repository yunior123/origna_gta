import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? 'buyer1@test.origna.ca';
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Buyer Flow', () => {
    test.setTimeout(600_000);

    test('Complete Buyer Journey', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(120_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);

        // Standardized Profile Navigation
        const profileBtn = page.getByLabel('menu-profile').first();
        await expect(profileBtn).toBeVisible({ timeout: 30000 });
        await profileBtn.click();
        await page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // Profile Address mutation
        const menuAddr = page.getByLabel('menu-address').first();
        await expect(menuAddr).toBeVisible({ timeout: 30000 });
        await menuAddr.click();
        await page.waitForURL(/\/addresses(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        const addAddrBtn = page.getByLabel('btn_add_address').first();
        if (await addAddrBtn.isVisible()) {
            await addAddrBtn.click();
            await page.getByLabel('address_street_field').first().fill('100 Queen');
            // Wait for suggestions
            const suggestion = page.locator('flt-semantics[role="button"]').first();
            await expect(suggestion).toBeVisible({ timeout: 10000 });
            await suggestion.click();
            await page.goBack();
            await waitForFlutter(page);
        }

        await page.goBack(); // Profile
        await page.goBack(); // Home
        await waitForFlutter(page);

        // Cart Navigation
        const cartBtn = page.getByLabel('menu-cart').first();
        await expect(cartBtn).toBeVisible({ timeout: 30000 });
        await cartBtn.click();
        await page.waitForURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        const checkoutBtn = page.getByLabel('cart_checkout_button').first();
        if (await checkoutBtn.isVisible()) {
            await checkoutBtn.click();
            await page.waitForURL(/\/checkout(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await waitForFlutter(page);

            await expect(page.getByLabel('checkout_place_order_button').first()).toBeVisible();
            await page.goBack();
            await waitForFlutter(page);
        }

        await page.goBack(); // Home
        await waitForFlutter(page);
        await expect(page.getByLabel('menu-cart').first()).toBeAttached();
    });
});
