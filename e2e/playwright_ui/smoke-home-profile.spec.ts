import { test, expect } from '@playwright/test';
import {
    waitForFlutter,
    requireWebApp,
    checkSemantics,
    ensureLoggedInAsAdmin,
    performSignOut,
    navigateHome,
    BTN_SETTINGS_LABEL,
    BTN_CART,
} from './flutter-helpers';
import { TEST_ACCOUNTS } from './api-helpers';

/**
 * REPLICA of integration_test/flows/smoke_home_profile_test.dart
 */

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://dev.orignagta.ca';
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = TEST_ACCOUNTS.ADMIN_PASS;

test.describe('PW IT Replica — Smoke Home + Profile (admin)', () => {
    test.setTimeout(600_000);

    test('replica', async ({ page }) => {
        await requireWebApp(page, TARGET_URL);
        page.setDefaultTimeout(60_000);

        const ensureOnHome = async () => {
            // Use URL to determine actual current route — Flutter Web keeps background
            // routes alive in the semantic tree, so element visibility alone is not
            // sufficient to confirm we are on the home screen.
            const homeUrl = `${TARGET_URL}/`;
            const isOnHome = () => page.url() === homeUrl || page.url() === TARGET_URL;

            // Flutter Web 3.41.3: semantic labels are in textContent, not aria-label.
            // getByRole uses Chrome's AOM (reads textContent) — works correctly.
            const settingsLocator = () => page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();

            if (isOnHome()) {
                const btn = settingsLocator();
                const attached = await btn.waitFor({ state: 'attached', timeout: 30000 })
                    .then(() => true).catch(() => false);
                if (attached) return btn;
            }

            // Not on home URL — navigate there via in-app back navigation.
            await navigateHome(page, TARGET_URL);
            await waitForFlutter(page);

            // If navigateHome fell back to page.goto, auth state may be cleared.
            const homeAttached = await settingsLocator().waitFor({ state: 'attached', timeout: 10000 })
                .then(() => true).catch(() => false);
            if (!homeAttached) {
                await page.waitForTimeout(3000);
                const stillGone = !(await settingsLocator().waitFor({ state: 'attached', timeout: 5000 })
                    .then(() => true).catch(() => false));
                if (stillGone) {
                    await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);
                    await navigateHome(page, TARGET_URL);
                    await waitForFlutter(page);
                }
            }

            return settingsLocator();
        };

        // C001/C002: App renders Flutter Web with semantics
        await page.goto(`${TARGET_URL}/`, { waitUntil: 'domcontentloaded' });
        await waitForFlutter(page);
        await checkSemantics(page);

        // Establish admin session (returns on home page)
        await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASSWORD);
        await navigateHome(page, TARGET_URL);
        await waitForFlutter(page);

        // C004: settings button visible after login
        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
        if (!(await settingsBtn.isVisible({ timeout: 3000 }).catch(() => false))) {
            const profileBackBtn = page.getByRole('button', { name: /^back$/i }).first();
            if (await profileBackBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
                await profileBackBtn.click({ force: true });
                await waitForFlutter(page);
            }
        }
        await expect(settingsBtn).toBeAttached({ timeout: 60000 });

        // C006/C007: Cart button visible and navigates to /cart
        const cartBtn = page.getByRole('button', { name: BTN_CART }).first();
        await expect(cartBtn).toBeAttached();
        await cartBtn.click();
        const cartTitle = page.locator('flt-semantics').filter({ hasText: /your cart|votre panier/i }).first();
        const reachedCartByUrl = await page
            .waitForURL(/\/cart/i, { timeout: 15000 })
            .then(() => true)
            .catch(() => false);
        if (!reachedCartByUrl) {
            const reachedCartByTitle = await cartTitle.isVisible({ timeout: 8000 }).catch(() => false);
            if (!reachedCartByTitle) {
                // Retry click once (Flutter semantics can rebind after auth rebuild).
                await cartBtn.click();
                await page.waitForURL(/\/cart/i, { timeout: 15000 }).catch(() => {});
            }
        }
        const isCartUrl = /\/cart/i.test(page.url());
        const isCartTitleVisible = await cartTitle.isVisible({ timeout: 3000 }).catch(() => false);
        expect(isCartUrl || isCartTitleVisible).toBeTruthy();
        await navigateHome(page, TARGET_URL);
        await waitForFlutter(page);

        // C008: Seeded product search loop
        // Product card groups use aria-label attribute (unlike buttons which use textContent).
        // [aria-label*="product-card-"] correctly selects flt-semantics[role="group"] elements.
        const productCards = page.locator('[aria-label*="product-card-"]');
        for (let i = 0; i < 12; i++) {
            if ((await productCards.count()) > 0) break;
            await page.mouse.wheel(0, 220);
            await page.waitForTimeout(500);
        }
        const productCardCount = await productCards.count();
        expect(productCardCount, 'At least one product card should be visible on home').toBeGreaterThan(0);
        // Navigate into a product card and back.
        // Use navigateHome() for the return trip — it handles Flutter's "Go back"
        // tooltip button (product-details uses replaceState so browser goBack may
        // go to /login instead of home, wiping in-memory auth).
        if (productCardCount > 0) {
            await productCards.first().click();
            // Wait for URL to reach product-details (confirms in-app SPA navigation).
            const reachedProduct = await page.waitForURL(/\/product-details/i, { timeout: 10000 })
                .then(() => true).catch(() => false);
            console.log(`   ℹ️  C008 product nav — URL after click: ${page.url()} (reachedProduct=${reachedProduct})`);
            await page.waitForTimeout(1000);
            // Use navigateHome — handles "Go Back"/"Retour" tooltips on product-details
            // back button; does NOT return early on background home route elements.
            await navigateHome(page, TARGET_URL);
            await waitForFlutter(page);
            console.log(`   ℹ️  C008 after navigateHome — URL: ${page.url()}`);
        }

        // A08: Home scroll interaction + pull-to-refresh coverage
        // The home screen wraps its list in a RefreshIndicator (added in recent UI update).
        // Scrolling down then back up simulates the overscroll that can trigger refresh.
        // The test verifies the page remains stable (no crash, semantic content intact).
        await page.mouse.wheel(0, 300);
        await page.waitForTimeout(800);
        await page.mouse.wheel(0, -300);
        await page.waitForTimeout(800);
        // Overscroll upward from top — exercises the RefreshIndicator trigger threshold.
        // In Flutter Web, this does NOT reliably fire the onRefresh callback
        // (pointer events differ from touch), but the widget must not crash.
        await page.mouse.wheel(0, -200);
        await page.waitForTimeout(600);
        // Verify semantic tree is intact after overscroll
        const afterRefreshSemCount = await page.locator('flt-semantics').count();
        expect(afterRefreshSemCount, 'Semantic tree must survive pull-to-refresh overscroll').toBeGreaterThan(0);

        // C009: Profile navigation via settings button
        // Wait for Flutter semantic tree to stabilize after A08 overscroll interactions.
        // Overscroll can trigger RefreshIndicator rebuild, temporarily clearing flt-semantics.
        await waitForFlutter(page);
        console.log(`   ℹ️  C009 pre-click URL: ${page.url()}`);


        const profileSettingsBtn = await ensureOnHome();
        await expect(profileSettingsBtn).toBeAttached({ timeout: 30000 });
        await profileSettingsBtn.click({ force: true });
        await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
        await waitForFlutter(page);

        const ensureOnProfile = async () => {
            if (/\/profile/i.test(page.url())) {
                return;
            }
            // Some flows land on /orders after browser goBack due nested navigator
            // state; re-open profile through the settings route deterministically.
            const backBtn = page.locator('[aria-label^="btn-back"]').first();
            if (await backBtn.isVisible().catch(() => false)) {
                await backBtn.click();
                await waitForFlutter(page);
            }
            if (!/\/profile/i.test(page.url())) {
                await navigateHome(page, TARGET_URL);
                const dynamicSettingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
                await expect(dynamicSettingsBtn).toBeAttached({ timeout: 30000 });
                await dynamicSettingsBtn.click();
            }
            await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
            await waitForFlutter(page);
        };

        // T10: My Orders sub-page
        const menuOrders = page.locator('[aria-label^="menu-my-orders"]').first();
        if (await menuOrders.isVisible().catch(() => false)) {
            await menuOrders.click();
            await expect(page).toHaveURL(/\/orders/i, { timeout: 20000 });
            await page.goBack();
            await ensureOnProfile();
        }

        // T11: Favorites sub-page
        // Wait for semantic tree to fully rebuild after goBack (FadeSlideIn at 100ms offset)
        await page.waitForTimeout(2000);
        const menuFav = page.locator('[aria-label^="menu-favorites"]').first();
        await menuFav.waitFor({ state: 'attached', timeout: 15000 }).catch(() => {});
        if (await menuFav.isVisible().catch(() => false)) {
            await menuFav.scrollIntoViewIfNeeded().catch(() => {});
            await menuFav.click();
            await expect(page).toHaveURL(/\/favorites/i, { timeout: 20000 });
            await page.goBack();
            await ensureOnProfile();
        }

        // T12: Address sub-page
        // Wait for semantic tree to fully rebuild after goBack from favorites
        await page.waitForTimeout(2000);
        const menuAddr = page.locator('[aria-label^="menu-address"]').first();
        await menuAddr.waitFor({ state: 'attached', timeout: 15000 }).catch(() => {});
        if (await menuAddr.isVisible().catch(() => false)) {
            await menuAddr.scrollIntoViewIfNeeded().catch(() => {});
            await menuAddr.click();
            await expect(page).toHaveURL(/\/addresses/i, { timeout: 20000 });
            await page.goBack();
            await ensureOnProfile();
        }

        // C010/C079: Return to home after profile sub-pages
        await page.goBack();
        await waitForFlutter(page);
        await expect(settingsBtn).toBeAttached();

        // C080/C099: Sign-out flow
        await performSignOut(page, TARGET_URL);
    });
});
