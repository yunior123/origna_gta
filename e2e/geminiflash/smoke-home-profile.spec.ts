import { test, expect } from '@playwright/test';
import { waitForFlutter, requireWebApp, checkSemantics, ensureLoggedInAsAdmin } from './flutter-helpers';

/**
 * REPLICA of the Home + Profile Smoke Test.
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Smoke Home + Profile (admin)', () => {
    test.setTimeout(600_000);

    test('replica', async ({ page, request }) => {
        await requireWebApp(page, TARGET_URL);

        page.setDefaultTimeout(120_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        const sems = await page.locator('flt-semantics').count();
        if (sems === 0) {
            test.skip(true, 'No <flt-semantics> — run debug build with ensureSemantics enabled.');
        }


        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);

        // Standardized Profile Navigation
        const profileBtn = page.getByLabel('menu-profile').first();
        await expect(profileBtn).toBeVisible({ timeout: 30000 });

        const cartBtn = page.getByLabel('menu-cart').first();
        await expect(cartBtn).toBeVisible({ timeout: 30000 });
        await cartBtn.click();
        await expect(page).toHaveURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await page.goBack();
        await waitForFlutter(page);

        const productCards = page.locator('[aria-label^="product-card-"]');
        for (let i = 0; i < 12; i++) {
            if ((await productCards.count()) > 0) break;
            await page.mouse.wheel(0, 220);
            await page.waitForTimeout(500);
        }

        if ((await productCards.count()) > 0) {
            await productCards.first().click();
            await page.waitForTimeout(1500);
            await page.goBack();
            await waitForFlutter(page);
        }

        await page.mouse.wheel(0, 300);
        await page.waitForTimeout(800);
        await page.mouse.wheel(0, -300);
        await page.waitForTimeout(800);

        await profileBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        const menuOrders = page.getByLabel('menu-my-orders').first();
        if (await menuOrders.isVisible().catch(() => false)) {
            await menuOrders.click();
            await expect(page).toHaveURL(/\/orders(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        const menuFav = page.getByLabel('menu-favorites').first();
        if (await menuFav.isVisible().catch(() => false)) {
            await menuFav.click();
            await expect(page).toHaveURL(/\/favorites(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        const menuAddr = page.getByLabel('menu-address').first();
        if (await menuAddr.isVisible().catch(() => false)) {
            await menuAddr.click();
            await expect(page).toHaveURL(/\/addresses(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        await page.goBack();
        await waitForFlutter(page);
        await expect(profileBtn).toBeVisible();

        await profileBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });

        const signOut = page.getByLabel('btn-sign-out').first();
        await expect(signOut).toBeVisible();
        await signOut.click();

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await profileBtn.click();
        await expect(page.getByRole('button', { name: /sign\s*in|connexion/i }).first()).toBeVisible({ timeout: 20000 });
    });
});
