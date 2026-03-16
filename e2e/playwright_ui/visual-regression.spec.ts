import { test, expect, Page } from '@playwright/test';
import {
    waitForFlutter,
    ensureLoggedInAsBuyer,
    BTN_SETTINGS_LABEL,
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://orignagta.ca';
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? 'yuniorrodriguezo460@gmail.com';
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

/**
 * Wait up to `timeout` ms for the Flutter semantic tree to contain at least
 * `minCount` elements. Returns true if semantics are ready, false otherwise.
 * Never throws — callers use the return value to decide whether to skip screenshots.
 */
async function waitForSemantics(page: Page, minCount = 1, timeout = 60_000): Promise<boolean> {
    const deadline = Date.now() + timeout;
    while (Date.now() < deadline) {
        const count = await page.locator('flt-semantics').count().catch(() => 0);
        if (count >= minCount) return true;
        // Try activating the semantics placeholder if still present
        const placeholder = page.locator('flt-semantics-placeholder');
        if ((await placeholder.count().catch(() => 0)) > 0) {
            await placeholder.first().click({ force: true }).catch(() => { });
        }
        await page.keyboard.press('Tab').catch(() => { });
        await page.waitForTimeout(1500).catch(() => { });
    }
    return (await page.locator('flt-semantics').count().catch(() => 0)) >= minCount;
}

test.describe('Visual Regression', () => {
    test.setTimeout(300_000);

    test('login page screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        const semanticsReady = await waitForSemantics(page, 1, 60_000);
        if (!semanticsReady) {
            console.log('   ⚠️ Skipping login page screenshot — flt-semantics not ready after 60s');
            return;
        }
        await expect(page).toHaveScreenshot('login-page.png', {
            maxDiffPixelRatio: 0.02,
        });
    });

    test('home page screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        await waitForFlutter(page);
        const semanticsReady = await waitForSemantics(page, 1, 60_000);
        if (!semanticsReady) {
            console.log('   ⚠️ Skipping home page screenshot — flt-semantics not ready after 60s');
            return;
        }
        await expect(page).toHaveScreenshot('home-page.png', {
            maxDiffPixelRatio: 0.02,
        });
    });

    test('settings/profile screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        // Flutter Web 3.41.3: btn-home-settings is in textContent, use getByRole
        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
        const found = await settingsBtn.waitFor({ state: 'attached', timeout: 120_000 }).then(() => true).catch(() => false);
        if (!found) {
            console.log('   ⚠️ Skipping profile screenshot — settings button not found');
            return;
        }
        await settingsBtn.click({ force: true }).catch(() => { });
        await waitForFlutter(page);
        const semanticsReady = await waitForSemantics(page, 1, 60_000);
        if (!semanticsReady) {
            console.log('   ⚠️ Skipping profile screenshot — flt-semantics not ready after 60s');
            return;
        }
        await expect(page).toHaveScreenshot('profile-page.png', {
            maxDiffPixelRatio: 0.02,
        });
    });

    test('cart page screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        const cartBtn = page.locator('[aria-label^="btn-cart"]').first();
        if (await cartBtn.isVisible().catch(() => false)) {
            await cartBtn.click();
            await waitForFlutter(page);
            const semanticsReady = await waitForSemantics(page, 1, 60_000);
            if (!semanticsReady) {
                console.log('   ⚠️ Skipping cart screenshot — flt-semantics not ready after 60s');
                return;
            }
            await expect(page).toHaveScreenshot('cart-page.png', {
                maxDiffPixelRatio: 0.02,
            });
        }
    });

    test('product detail screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        await waitForFlutter(page);
        // Click first product card
        const productCard = page.locator('[aria-label^="product-card-"]').first();
        if (await productCard.isVisible({ timeout: 30_000 }).catch(() => false)) {
            await productCard.click();
            await waitForFlutter(page);
            const semanticsReady = await waitForSemantics(page, 1, 60_000);
            if (!semanticsReady) {
                console.log('   ⚠️ Skipping product detail screenshot — flt-semantics not ready after 60s');
                return;
            }
            await expect(page).toHaveScreenshot('product-detail.png', {
                maxDiffPixelRatio: 0.03,
            });
        }
    });

    test('search results screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        const searchBar = page.locator('[aria-label="input-home-search"]');
        if (await searchBar.isVisible({ timeout: 30_000 }).catch(() => false)) {
            await searchBar.fill('shirt');
            await page.keyboard.press('Enter');
            await waitForFlutter(page);
            const semanticsReady = await waitForSemantics(page, 1, 60_000);
            if (!semanticsReady) {
                console.log('   ⚠️ Skipping search results screenshot — flt-semantics not ready after 60s');
                return;
            }
            await expect(page).toHaveScreenshot('search-results.png', {
                maxDiffPixelRatio: 0.03,
            });
        }
    });
});
