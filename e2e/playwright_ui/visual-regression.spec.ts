import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    ensureLoggedInAsBuyer,
    BTN_SETTINGS_LABEL,
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://orignagta.ca';
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? 'yuniorrodriguezo460@gmail.com';
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('Visual Regression', () => {
    test.setTimeout(300_000);

    test('login page screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await expect(page).toHaveScreenshot('login-page.png', {
            maxDiffPixelRatio: 0.02,
        });
    });

    test('home page screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        await waitForFlutter(page);
        await expect(page).toHaveScreenshot('home-page.png', {
            maxDiffPixelRatio: 0.02,
        });
    });

    test('settings/profile screenshot', async ({ page }) => {
        await page.goto(TARGET_URL);
        await waitForFlutter(page);
        await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        const settingsBtn = page.locator(`[aria-label="${BTN_SETTINGS_LABEL}"]`).first();
        await settingsBtn.waitFor({ state: 'attached', timeout: 120_000 });
        await settingsBtn.click();
        await waitForFlutter(page);
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
            await expect(page).toHaveScreenshot('search-results.png', {
                maxDiffPixelRatio: 0.03,
            });
        }
    });
});
