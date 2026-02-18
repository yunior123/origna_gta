/**
 * STRICT REPLICA (Playwright) of:
 *   origna_gta/integration_test/flows/smoke_home_profile_test.dart
 *
 * Constraints:
 * - DEV Firebase only (no emulators)
 * - Use Flutter Web semantics / ARIA locators (no Flutter Keys)
 *
 * App (debug web-server):
 *   cd origna_gta && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5005 \
 *     --dart-define=ENVIRONMENT=dev --dart-define=USE_EMULATORS=false
 *
 * Test:
 *   cd e2e && E2E_TARGET_URL=http://127.0.0.1:5005 \
 *     E2E_ADMIN_EMAIL=... E2E_ADMIN_PASSWORD=... \
 *     npx playwright test pw-it-smoke-home-profile.spec.ts --project=chromium --workers=1
 */

import { test, expect } from '@playwright/test';
import { waitForFlutter } from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD;

async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${TARGET_URL}/`).catch(() => null);
  const status = res?.status?.();
  if (!status || status < 200 || status >= 400) {
    test.skip(true, `Target not reachable at ${TARGET_URL} (status: ${status ?? 'ERR'})`);
  }
}

async function ensureLoggedInAsAdmin(page: any) {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
    test.skip(true, 'Missing E2E_ADMIN_EMAIL / E2E_ADMIN_PASSWORD');
  }

  const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
  await expect(settingsBtn).toBeAttached();
  await settingsBtn.click();

  const loginSignIn = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();
  const loginPromptVisible = await loginSignIn.isVisible().catch(() => false);
  if (!loginPromptVisible) {
    // Already logged in (or navigated to /profile). Confirm /profile.
    await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
    return;
  }

  await loginSignIn.click();
  await expect(page).toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
  await waitForFlutter(page, 120_000);

  const emailInput = page.getByRole('textbox', { name: /email/i }).first();
  await expect(emailInput).toBeVisible({ timeout: 20_000 });
  await emailInput.fill(ADMIN_EMAIL);

  const passwordInput = page.getByRole('textbox', { name: /password/i }).first();
  await passwordInput.fill(ADMIN_PASSWORD);

  const submit = page.getByRole('button', { name: /sign\s*in|connexion|log\s*in/i }).first();
  await submit.click();
  await expect(page).not.toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 30_000 });

  // Back to home then open profile.
  await page.goto(`${TARGET_URL}/`);
  await waitForFlutter(page, 120_000);
  await settingsBtn.click();
  await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
}

test.describe('PW IT Replica — Smoke Home + Profile (admin)', () => {
  test.setTimeout(6 * 60_000);

  test('replica', async ({ page, request }) => {
    await requireWebApp(request);

    page.setDefaultTimeout(120_000);
    page.setDefaultNavigationTimeout(120_000);

    // Bootstrap (C001/C002)
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page, 120_000);
    const sems = await page.locator('flt-semantics').count();
    if (sems === 0) {
      test.skip(true, 'No <flt-semantics> — run debug build with ensureSemantics enabled.');
    }

    // Establish ADMIN session (Flutter establishSession analogue)
    await ensureLoggedInAsAdmin(page);
    await waitForFlutter(page, 120_000);

    // Back home (Flutter continues from home)
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page, 120_000);

    // C004: settings button visible after login
    await expect(page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first()).toBeAttached();

    // C006/C007: cart icon visible and cart opens
    const cartBtn = page.getByRole('button', { name: /cart|shopping|panier/i }).first();
    await expect(cartBtn).toBeAttached();
    await cartBtn.click();
    await expect(page).toHaveURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
    await page.goBack();
    await waitForFlutter(page, 120_000);

    // Seeded product search loop (up to 12 retries with scroll)
    const productCards = page.locator('[aria-label^="product-card-"]');
    for (let i = 0; i < 12; i++) {
      if ((await productCards.count()) > 0) break;
      await page.mouse.wheel(0, 220);
      await page.waitForTimeout(500);
    }

    // C008: open product detail if any product exists
    if ((await productCards.count()) > 0) {
      await productCards.first().click();
      await page.waitForTimeout(1500);
      await page.goBack();
      await waitForFlutter(page, 120_000);
    }

    // A08: home scroll interaction
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(800);
    await page.mouse.wheel(0, -300);
    await page.waitForTimeout(800);

    // PROFILE NAVIGATION START (C009)
    const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
    await waitForFlutter(page, 120_000);

    // T10 My Orders
    const menuOrders = page.locator('[aria-label="menu-my-orders"]').first();
    if (await menuOrders.isVisible().catch(() => false)) {
      await menuOrders.click();
      await expect(page).toHaveURL(/\/orders(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
      await page.goBack();
      await waitForFlutter(page, 120_000);
    }

    // T11 Favorites
    const menuFav = page.locator('[aria-label="menu-favorites"]').first();
    if (await menuFav.isVisible().catch(() => false)) {
      await menuFav.click();
      await expect(page).toHaveURL(/\/favorites(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
      await page.goBack();
      await waitForFlutter(page, 120_000);
    }

    // T12 Address
    const menuAddr = page.locator('[aria-label="menu-address"]').first();
    if (await menuAddr.isVisible().catch(() => false)) {
      await menuAddr.click();
      await expect(page).toHaveURL(/\/addresses(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
      await page.goBack();
      await waitForFlutter(page, 120_000);
    }

    // Return to home
    await page.goBack();
    await waitForFlutter(page, 120_000);
    await expect(page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first()).toBeAttached();

    // SIGN OUT FLOW (C080/C099)
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });

    const signOut = page.locator('[aria-label="btn-sign-out"]').first();
    await expect(signOut).toBeAttached();
    await signOut.click();

    // After sign out, tapping settings should show login prompt.
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page, 120_000);
    await settingsBtn.click();
    await expect(page.getByRole('button', { name: /sign\s*in|connexion/i }).first()).toBeVisible({ timeout: 20_000 });
  });
});
