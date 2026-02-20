import { test, expect } from '@playwright/test';
import {
    signIn,
    writeDoc,
    toFirestoreFields,
    getDoc,
    TEST_UIDS,
    TEST_ACCOUNTS,
    WEB_APP_URL,
    DEFAULT_PASS,
    setProductTrending,
    createDummyProduct
} from './api-helpers';
import {
    requireWebApp,
    waitForFlutter,
    ensureLoggedInAsAdmin,
    checkSemantics,
    BTN_SETTINGS
} from './flutter-helpers';

test.describe('Trending Products flows', () => {
    let userEmail = TEST_ACCOUNTS.BUYER_EMAIL;
    let userPass = DEFAULT_PASS;
    let userId = TEST_UIDS.BUYER;

    test.beforeEach(async () => {
        // Authenticate once as admin for the data setup
        const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);

        // Force the buyer to be a premium member so they can access the notification preferences
        await writeDoc(`users/${userId}`, toFirestoreFields({
            email: userEmail,
            isPremium: true,
            notifyTrending: false // Start with it off to test toggling
        }), adminAuth.idToken);
    });

    test('Premium user can toggle Trending Products notifications', async ({ page }) => {
        // 1. Ensure target URL is reachable
        await requireWebApp(page, WEB_APP_URL);
        page.setDefaultTimeout(60_000);

        // 2. Load the page and wait for Flutter web initialization
        await page.goto(`${WEB_APP_URL}/`);
        await waitForFlutter(page);
        await checkSemantics(page);

        // 3. Login using the universal Flutter helper flow (works for any user role, despite the name)
        await ensureLoggedInAsAdmin(page, WEB_APP_URL, userEmail, userPass);

        // 4. Open Profile
        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
        await settingsBtn.click();
        await expect(page).toHaveURL(/\/profile/i, { timeout: 20000 });
        await waitForFlutter(page);

        // 5. Go to Premium Subscription using the semantics label
        const premiumBtn = page.locator('[aria-label^="menu-premium"]').first();
        await premiumBtn.click();
        await expect(page).toHaveURL(/\/subscription/i, { timeout: 20000 });
        await waitForFlutter(page);

        // 6. Toggle the Trending Products switch
        const trendingListTile = page.locator('text=Trending Products').first();
        await expect(trendingListTile).toBeVisible();
        await trendingListTile.click();

        // 7. Verification: Wait a brief moment for the Firestore update to propagate
        await page.waitForTimeout(2000);

        let updatedDoc;
        for (let i = 0; i < 5; i++) {
            updatedDoc = await getDoc(`users/${userId}`);
            if (updatedDoc?.notifyTrending === true) {
                break;
            }
            await page.waitForTimeout(1000);
        }

        expect(updatedDoc?.notifyTrending).toBe(true);
    });

    test('Admin can mark a product as trending programmatically', async () => {
        const adminToken = (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS)).idToken;
        const testProduct = await createDummyProduct(TEST_UIDS.ADMIN, 'TREND');

        await setProductTrending(testProduct.id, true, adminToken);

        const updatedProductDoc = await getDoc(`products/${testProduct.id}`, adminToken);
        expect(updatedProductDoc.isTrending).toBe(true);
        expect(updatedProductDoc.trendingAt).toBeDefined();

        // Cleanup
        await setProductTrending(testProduct.id, false, adminToken);
    });
});
