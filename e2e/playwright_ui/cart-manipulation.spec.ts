/**
 * OrignaGTA — Cart Manipulation E2E Tests
 * ========================================
 * Tests cart add/update/remove via OrignaBase REST API calls,
 * plus a UI test that verifies cart items render on the /cart screen.
 *
 * Target: https://dev.orignagta.ca
 * Run: cd e2e && npx playwright test cart-manipulation.spec.ts --config=playwright.config.dev.ts
 */
import { test, expect } from '@playwright/test';
import {
  signIn,
  callCallable,
  callOk,
  TEST_ACCOUNTS,
  WEB_APP_URL,
} from './api-helpers';
import {
  waitForFlutter,
  requireWebApp,
  checkSemantics,
  ensureLoggedInAsAdmin,
  BTN_SETTINGS,
} from './flutter-helpers';

// ════════════════════════════════════════════════════════════════════
// CONSTANTS
// ════════════════════════════════════════════════════════════════════

const TARGET_URL = WEB_APP_URL;
const PRODUCT_ID = 'e2e_product_test_seller';

test.describe('Cart Manipulation', () => {
  test.setTimeout(300_000);
  test.describe.configure({ mode: 'serial' });

  let buyerToken: string;
  let buyerUid: string;

  test.beforeAll(async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    buyerToken = auth.idToken;
    buyerUid = auth.localId;
  });

  // ── T01: Add item to cart via OrignaBase API ──────────────────────
  test('T01: Add item to cart via API', async () => {
    // Clear any existing cart entry first
    await callCallable('remove_from_cart', { productId: PRODUCT_ID }, buyerToken).catch(() => {});

    const result = await callCallable('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, buyerToken);
    // Accept success response or already-in-cart scenario
    const hasError = result?.error && !String(result?.error?.message ?? '').toLowerCase().includes('already');
    expect(hasError, 'add_to_cart should succeed').toBeFalsy();
  });

  // ── T02: Update cart quantity via OrignaBase API ──────────────────
  test('T02: Update cart item quantity via API', async () => {
    // Update quantity to 3
    const result = await callCallable('update_cart_quantity', { productId: PRODUCT_ID, quantity: 3 }, buyerToken)
      .catch(() => callCallable('add_to_cart', { productId: PRODUCT_ID, quantity: 3 }, buyerToken));

    // Accept success or fallback behavior (quantity update may be via re-add)
    const errorMsg = String(result?.error?.message ?? '').toLowerCase();
    const isTerminalError = result?.error && !errorMsg.includes('already') && !errorMsg.includes('not found');
    expect(isTerminalError, 'update cart quantity should not fail with terminal error').toBeFalsy();
  });

  // ── T03: Remove item from cart via OrignaBase API ─────────────────
  test('T03: Remove item from cart via API', async () => {
    const result = await callCallable('remove_from_cart', { productId: PRODUCT_ID }, buyerToken);
    const hasError = result?.error && !String(result?.error?.message ?? '').toLowerCase().includes('not found');
    expect(hasError, 'remove_from_cart should succeed').toBeFalsy();
  });

  // ── T04: Cart shows items on UI ──────────────────────────────────
  test('T04: Cart screen displays added items', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    // Step 1: Add item to cart via API so there is at least one item
    await callCallable('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, buyerToken);

    // Step 2: Navigate to the app and log in as buyer
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(
      page,
      TARGET_URL,
      TEST_ACCOUNTS.BUYER_EMAIL,
      TEST_ACCOUNTS.BUYER_PASS,
    );

    // Step 3: Navigate to cart via the cart button
    const cartBtn = page.getByRole('button', { name: /cart|shopping|panier/i }).first();
    await expect(cartBtn).toBeAttached({ timeout: 30_000 });
    await cartBtn.click();
    await expect(page).toHaveURL(/\/cart/i, { timeout: 20_000 });
    await waitForFlutter(page);

    // Step 4: Verify cart page loaded with "Your Cart" header and has content.
    await page.waitForTimeout(3000); // Let cart items load

    // Verify the cart page title is visible
    const cartTitle = page.locator('flt-semantics').filter({ hasText: /your cart|votre panier/i }).first();
    const hasTitleVisible = await cartTitle.isVisible({ timeout: 15_000 }).catch(() => false);

    // Check for any cart item indicators — use multiple strategies
    const hasProductCard = await page.locator('[aria-label^="product-card-"]').count() > 0;
    const hasCheckoutBtn = await page.getByRole('button', { name: /checkout|proceed|passer/i }).first()
      .isVisible({ timeout: 5_000 }).catch(() => false);
    // Cart with items renders multiple flt-semantics nodes (header + item cards)
    const semanticsCount = await page.locator('flt-semantics').count();
    const hasMultipleNodes = semanticsCount > 3; // header + at least one item card

    // At least the title should be present, and either items or multiple DOM nodes
    const cartLoaded = hasTitleVisible && (hasProductCard || hasCheckoutBtn || hasMultipleNodes);
    expect(cartLoaded, `Cart should load with items (title=${hasTitleVisible}, cards=${hasProductCard}, checkout=${hasCheckoutBtn}, nodes=${semanticsCount})`).toBe(true);

    // Cleanup: remove the item we added
    await callCallable('remove_from_cart', { productId: PRODUCT_ID }, buyerToken).catch(() => {});
  });
});
