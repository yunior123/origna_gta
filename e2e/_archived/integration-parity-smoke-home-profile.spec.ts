/**
 * Integration Parity — Smoke (Home + Profile)
 *
 * Mirrors the intent of `origna_gta/integration_test/flows/smoke_home_profile_test.dart`
 * but using Playwright + Flutter Web Semantics.
 *
 * Notes:
 * - This spec targets DEV Firebase in a local debug web build (no emulators).
 * - Some steps are conditional (products may not be present; user may be guest).
 */

import { test, expect } from '@playwright/test';
import { waitForFlutter, hasSemanticLabel } from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://localhost:5005';
const EXPECT_FIREBASE_PROJECT_ID = process.env.E2E_EXPECT_FIREBASE_PROJECT_ID;
const FORCE_GUEST = process.env.E2E_FORCE_GUEST === '1' || process.env.E2E_FORCE_GUEST === 'true';

async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${TARGET_URL}/`).catch(() => null);
  const status = res?.status?.();
  if (!status || status < 200 || status >= 400) {
    test.skip(true, `Target not reachable at ${TARGET_URL} (status: ${status ?? 'ERR'})`);
  }
}

async function maybeForceGuest(page: any) {
  if (!FORCE_GUEST) return;
  await page.context().clearCookies().catch(() => {});
  await page.evaluate(async () => {
    try { localStorage.clear(); } catch {}
    try { sessionStorage.clear(); } catch {}
    try {
      // @ts-ignore
      const dbs = (indexedDB.databases ? await indexedDB.databases() : []) as any[];
      for (const db of dbs) {
        if (db && db.name) indexedDB.deleteDatabase(db.name);
      }
    } catch {}
  });
  await page.reload();
}

test.describe('Integration parity — Smoke Home+Profile', () => {
  test.setTimeout(120_000);

  test('Smoke flow (guest-compatible)', async ({ page, request }) => {
    await requireWebApp(request);

    const expectProjectId = EXPECT_FIREBASE_PROJECT_ID?.trim();
    const expectProjectIdEncoded = expectProjectId ? encodeURIComponent(expectProjectId) : undefined;
    const projectProbe = expectProjectId
      ? page
          .waitForEvent('request', {
            predicate: (req: any) => {
              const url = req.url();
              if (url.includes(expectProjectId)) return true;
              if (expectProjectIdEncoded && url.includes(expectProjectIdEncoded)) return true;
              const body = req.postData() ?? '';
              if (body.includes(expectProjectId)) return true;
              if (expectProjectIdEncoded && body.includes(expectProjectIdEncoded)) return true;
              return false;
            },
            timeout: 20_000,
          })
          .catch(() => null)
      : Promise.resolve(null);

    // A01/C001/C002 equivalents: app boots and semantics are available.
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await maybeForceGuest(page);
    await waitForFlutter(page);

    const semanticsCount = await page.locator('flt-semantics').count();
    if (semanticsCount === 0) {
      test.skip(true, 'No <flt-semantics> found — run a debug web build with ensureSemantics enabled.');
    }

    // Home search present (rough equivalent of home render checks).
    const search = page
      .getByRole('textbox', { name: /search|rechercher/i })
      .first()
      .or(page.getByLabel(/search|rechercher/i).first());
    await expect(search).toBeVisible({ timeout: 20_000 });

    // Cart icon check + tap.
    const cartBtn = page.getByRole('button', { name: /cart|shopping|panier/i }).first();
    await expect(cartBtn).toBeAttached();
    await cartBtn.click();

    // If guest, expect login prompt. If logged-in, expect cart page.
    const loginCancel = page.getByRole('button', { name: /cancel|annuler/i }).first();
    const loginSignIn = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();

    const cartSignal = await Promise.race([
      page.waitForURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 10_000 }).then(() => 'cart-route' as const),
      loginSignIn.waitFor({ state: 'visible', timeout: 10_000 }).then(() => 'login-prompt' as const),
      loginCancel.waitFor({ state: 'visible', timeout: 10_000 }).then(() => 'login-prompt' as const),
    ]).catch(() => null);

    expect(cartSignal, 'Expected either /cart navigation or login prompt after clicking cart.').toBeTruthy();
    if (cartSignal === 'login-prompt') {
      await loginCancel.click().catch(() => page.keyboard.press('Escape'));
    } else {
      // Basic cart scaffold-ish check: proceed button or checkout wording.
      await expect(page.getByRole('button', { name: /checkout|proceed|payer|caisse/i }).first()).toBeAttached({ timeout: 10_000 });
      await page.goBack().catch(() => page.goto(`${TARGET_URL}/`));
      await waitForFlutter(page);
    }

    // Product open: optional (depends on data in DEV).
    await page.waitForTimeout(1_000);
    const productCards = page.locator('[aria-label*="product-card-"]');
    const cardCount = await productCards.count();
    if (cardCount > 0) {
      await productCards.first().click();
      // Expect some action button present (add to cart or back)
      const backBtn = page.getByRole('button', { name: /back|retour/i }).first();
      const addToCartBtn = page.locator('[aria-label*="btn-add-to-cart-"]').first();
      await Promise.race([
        backBtn.waitFor({ state: 'attached', timeout: 12_000 }),
        addToCartBtn.waitFor({ state: 'attached', timeout: 12_000 }),
      ]).catch(() => {});
      await page.goBack().catch(() => page.keyboard.press('Escape'));
      await waitForFlutter(page);
    }

    // Home scroll interaction.
    await page.mouse.wheel(0, 600);
    await page.waitForTimeout(400);
    await page.mouse.wheel(0, -600);
    await page.waitForTimeout(400);

    // Settings -> /profile if logged in, else login prompt.
    const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
    await expect(settingsBtn).toBeAttached();
    await settingsBtn.click();

    const settingsSignal = await Promise.race([
      page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 12_000 }).then(() => 'profile-route' as const),
      loginSignIn.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
      loginCancel.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
    ]).catch(() => null);

    expect(settingsSignal, 'Expected either /profile navigation or login prompt after clicking Settings.').toBeTruthy();

    if (settingsSignal === 'login-prompt') {
      // Demonstrate navigation to login.
      await loginSignIn.click();
      await expect(page).toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 15_000 });
      await waitForFlutter(page);

      // Login screen should expose email textbox.
      await expect(page.getByRole('textbox', { name: /email/i }).first()).toBeAttached({ timeout: 15_000 });
    } else {
      // On profile route: check that at least one known semantic label exists.
      const hasSignOut = await hasSemanticLabel(page, 'profile_sign_out_button');
      const hasMyOrders = await hasSemanticLabel(page, 'profile_my_orders_button');
      expect(hasSignOut || hasMyOrders).toBeTruthy();
    }

    if (expectProjectId) {
      const matched = await projectProbe;
      expect(
        matched,
        `Expected at least one network request mentioning Firebase projectId "${expectProjectId}". Start Flutter with --dart-define=ENVIRONMENT=dev --dart-define=USE_EMULATORS=false.`,
      ).toBeTruthy();
    }
  });
});
