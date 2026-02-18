import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/smoke_home_profile_test.dart
 *
 * Flutter Key → Playwright selector mapping:
 *   home_settings_button → getByRole('button', { name: /settings/i })   (tooltip="Settings")
 *   home_cart_button     → getByRole('button', { name: /cart|shopping/i }) (tooltip="Shopping cart")
 *   profile menu items   → locator('[aria-label="menu-my-orders"]') etc. (semanticLabel in profile_screen.dart)
 *   btn-sign-out         → locator('[aria-label="btn-sign-out"]')
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? 'yr62813@gmail.com';
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? '960227Y#y';

test.describe('PW IT Replica — Smoke Home + Profile (admin)', () => {
    test.setTimeout(300_000); // 5 min; runs in parallel with other 4 tests

    test('replica', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        // C001/C002: App renders Flutter Web with semantics
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // Establish admin session (analogous to establishSession in Flutter)
        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);

        // Back to home — always start from a clean state
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        // C004: settings button visible after login (tooltip "Settings" → aria-label)
        const settingsBtn = page.getByRole('button', { name: /settings/i }).first();
        await expect(settingsBtn).toBeAttached();

        // C006/C007: Cart button visible and navigates to /cart
        const cartBtn = page.getByRole('button', { name: /cart|shopping/i }).first();
        await expect(cartBtn).toBeAttached();
        await cartBtn.click();
        await expect(page).toHaveURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await page.goBack();
        await waitForFlutter(page);

        // C008: Seeded product search loop (<=12 retries) + open product detail if found
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

        // A08: Home scroll interaction
        await page.mouse.wheel(0, 300);
        await page.waitForTimeout(800);
        await page.mouse.wheel(0, -300);
        await page.waitForTimeout(800);

        // C009: Profile navigation via settings button
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
        await waitForFlutter(page);

        // T10: My Orders sub-page
        const menuOrders = page.locator('[aria-label="menu-my-orders"]').first();
        if (await menuOrders.isVisible().catch(() => false)) {
            await menuOrders.click();
            await expect(page).toHaveURL(/\/orders(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // T11: Favorites sub-page
        const menuFav = page.locator('[aria-label="menu-favorites"]').first();
        if (await menuFav.isVisible().catch(() => false)) {
            await menuFav.click();
            await expect(page).toHaveURL(/\/favorites(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // T12: Address sub-page
        const menuAddr = page.locator('[aria-label="menu-address"]').first();
        if (await menuAddr.isVisible().catch(() => false)) {
            await menuAddr.click();
            await expect(page).toHaveURL(/\/addresses(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C010/C079: Return to home after profile sub-pages
        await page.goBack();
        await waitForFlutter(page);
        await expect(settingsBtn).toBeAttached();

        // C080/C099: Sign-out flow (shared helper)
        await performSignOut(page, TARGET_URL);
    });
});
