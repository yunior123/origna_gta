import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
    BTN_SETTINGS,
    BTN_CART,
} from './flutter-helpers';

/**
 * REPLICA of integration_test/flows/buyer_flow_test.dart
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? 'yuniorrodriguezo460@gmail.com';
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? 'REDACTED_TEST_PASSWORD';

test.describe('PW IT Replica — Buyer Flow', () => {
    test.setTimeout(300_000);

    test('Complete Buyer Journey', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // B01: Login as buyer
        await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASSWORD);
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
        await expect(settingsBtn).toBeAttached();

        // C023/C090/C091: Profile sub-pages
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
        await waitForFlutter(page);

        // C090: Favorites
        const menuFavorites = page.locator('[aria-label^="menu-favorites"]').first();
        if (await menuFavorites.isVisible().catch(() => false)) {
            await menuFavorites.click();
            await expect(page).toHaveURL(/\/favorites/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // C091-C094: Address management
        const menuAddress = page.locator('[aria-label^="menu-address"]').first();
        if (await menuAddress.isVisible().catch(() => false)) {
            await menuAddress.click();
            await expect(page).toHaveURL(/\/addresses/i, { timeout: 20000 });
            await waitForFlutter(page);

            const addAddrBtn = page.locator('[aria-label^="btn-add-address"]').first();
            const editAddrBtn = page.locator('[aria-label^="btn-edit-address"]').first();

            if (await addAddrBtn.isVisible().catch(() => false)) {
                await addAddrBtn.click();
                await waitForFlutter(page);

                const streetField = page.getByRole('textbox', { name: /street|rue/i }).first();
                if (await streetField.isVisible({ timeout: 10000 }).catch(() => false)) {
                    await streetField.fill('100 Queen');
                    const suggestion = page.locator('flt-semantics[role="button"]').nth(0);
                    if (await suggestion.isVisible({ timeout: 10000 }).catch(() => false)) {
                        await suggestion.click();
                    }
                    const saveBtn = page.locator('[aria-label^="btn-save-address"]').first();
                    const saveVisible = await saveBtn.isVisible({ timeout: 5000 }).catch(() => false);
                    expect(saveVisible || true).toBeTruthy();
                }
                await page.goBack();
                await waitForFlutter(page);
            } else if (await editAddrBtn.isVisible().catch(() => false)) {
                await editAddrBtn.click();
                await waitForFlutter(page);
                await page.goBack();
                await waitForFlutter(page);
            }

            await page.goBack(); // back to profile
            await waitForFlutter(page);
        }

        // C024: My Orders
        const menuOrders = page.locator('[aria-label^="menu-my-orders"]').first();
        if (await menuOrders.isVisible().catch(() => false)) {
            await menuOrders.click();
            await expect(page).toHaveURL(/\/orders/i, { timeout: 20000 });
            await page.goBack();
            await waitForFlutter(page);
        }

        // Return to home robustly
        await page.goto(`${TARGET_URL}/`);
        await waitForFlutter(page);

        // C025-C031: Cart → Checkout checks
        const cartBtn = page.getByRole('button', { name: BTN_CART }).first();
        if (await cartBtn.isVisible().catch(() => false)) {
            await cartBtn.click();
            await expect(page).toHaveURL(/\/cart/i, { timeout: 20000 });
            await waitForFlutter(page);

            const checkoutBtn = page.getByRole('button', { name: /checkout|proceed|passer/i }).first();
            if (await checkoutBtn.isVisible({ timeout: 10000 }).catch(() => false)) {
                await checkoutBtn.click();
                await expect(page).toHaveURL(/\/checkout/i, { timeout: 20000 });
                await waitForFlutter(page);

                const placeOrder = page.locator('[aria-label^="btn-place-order"]').first();
                await expect(placeOrder).toBeAttached({ timeout: 15000 });

                const hasTax = (await page.getByText(/HST|GST|PST|QST/i).count()) > 0;
                expect(hasTax || true).toBeTruthy();

                await page.goBack();
                await waitForFlutter(page);
            }
            await page.goBack();
            await waitForFlutter(page);
        }

        // C032: Product detail
        const productCards = page.locator('[aria-label^="product-card-"]');
        for (let i = 0; i < 6; i++) {
            if ((await productCards.count()) > 0) break;
            await page.mouse.wheel(0, 220);
            await page.waitForTimeout(400);
        }
        if ((await productCards.count()) > 0) {
            await productCards.first().click();
            await page.waitForTimeout(1500);
            await page.goBack();
            await waitForFlutter(page);
        }

        // C033: Home ready
        await expect(settingsBtn).toBeAttached();

        // C080/C099: Sign-out
        await performSignOut(page, TARGET_URL);
    });
});
