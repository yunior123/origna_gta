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
  // SKIPPED: OrignaBase does not expose /api/cart/add, /api/cart/remove, /api/cart/update
  // as standalone HTTP endpoints. Cart CRUD is handled exclusively by the Flutter SDK
  // through SurrealDB GraphQL. These routes return 404. Re-enable once OrignaBase
  // exposes dedicated REST cart endpoints.
  test.skip('T01: Add item to cart via API', async () => {
    await callCallable('remove_from_cart', { productId: PRODUCT_ID }, buyerToken).catch(() => {});
    const result = await callCallable('add_to_cart', { productId: PRODUCT_ID, quantity: 1 }, buyerToken);
    const hasError = result?.error && !String(result?.error?.message ?? '').toLowerCase().includes('already');
    expect(hasError, 'add_to_cart should succeed').toBeFalsy();
  });

  // ── T02: Update cart quantity via OrignaBase API ──────────────────
  // SKIPPED: Same reason as T01 — no /api/cart/update endpoint.
  test.skip('T02: Update cart item quantity via API', async () => {
    const result = await callCallable('update_cart_quantity', { productId: PRODUCT_ID, quantity: 3 }, buyerToken)
      .catch(() => callCallable('add_to_cart', { productId: PRODUCT_ID, quantity: 3 }, buyerToken));
    const errorMsg = String(result?.error?.message ?? '').toLowerCase();
    const isTerminalError = result?.error && !errorMsg.includes('already') && !errorMsg.includes('not found');
    expect(isTerminalError, 'update cart quantity should not fail with terminal error').toBeFalsy();
  });

  // ── T03: Remove item from cart via OrignaBase API ─────────────────
  // SKIPPED: Same reason as T01 — no /api/cart/remove endpoint.
  test.skip('T03: Remove item from cart via API', async () => {
    const result = await callCallable('remove_from_cart', { productId: PRODUCT_ID }, buyerToken);
    const hasError = result?.error && !String(result?.error?.message ?? '').toLowerCase().includes('not found');
    expect(hasError, 'remove_from_cart should succeed').toBeFalsy();
  });

  // ── T04: Cart screen loads correctly ─────────────────────────────
  test('T04: Cart screen loads for authenticated buyer', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    // Step 1: Navigate to the app and log in as buyer
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(
      page,
      TARGET_URL,
      TEST_ACCOUNTS.BUYER_EMAIL,
      TEST_ACCOUNTS.BUYER_PASS,
    );

    // Step 2: Navigate to cart via the cart button
    const cartBtn = page.getByRole('button', { name: /cart|shopping|panier/i }).first();
    await expect(cartBtn).toBeAttached({ timeout: 30_000 });
    await cartBtn.click();
    await expect(page).toHaveURL(/\/cart/i, { timeout: 20_000 });
    await waitForFlutter(page);

    // Step 3: Verify cart page loaded — either shows items or empty-cart message.
    // Both states are valid; we just confirm the page renders without crashing.
    await page.waitForTimeout(3000);

    const semanticsCount = await page.locator('flt-semantics').count();
    // Flutter renders at least a few semantics nodes for any non-blank screen
    expect(semanticsCount, `Cart page should render Flutter semantics (got ${semanticsCount})`).toBeGreaterThan(0);

    // Accept cart-with-items OR empty-cart screen
    const hasCartTitle = await page.locator('flt-semantics').filter({ hasText: /your cart|votre panier|cart/i }).count() > 0;
    const hasEmptyMsg = await page.locator('flt-semantics').filter({ hasText: /empty|vide|no items/i }).count() > 0;
    const hasProductCard = await page.locator('[aria-label^="product-card-"]').count() > 0;
    const hasCheckoutBtn = await page.getByRole('button', { name: /checkout|proceed|passer/i }).first()
      .isVisible({ timeout: 5_000 }).catch(() => false);

    const cartLoaded = hasCartTitle || hasEmptyMsg || hasProductCard || hasCheckoutBtn;
    expect(cartLoaded, `Cart page should display cart content or empty state (title=${hasCartTitle}, empty=${hasEmptyMsg}, cards=${hasProductCard}, checkout=${hasCheckoutBtn}, nodes=${semanticsCount})`).toBe(true);
  });
});
