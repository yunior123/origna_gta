/**
 * Playwright parity: integration_test/flows/smoke_home_profile_test.dart
 *
 * Runs against a local Flutter Web debug build configured for DEV Firebase (no emulators).
 *
 * Recommended app run:
 *   cd origna_gta && flutter run -d chrome --web-port=5005 --dart-define=ENVIRONMENT=dev --dart-define=USE_EMULATORS=false
 *
 * Test run:
 *   cd e2e && E2E_TARGET_URL=http://localhost:5005 E2E_EXPECT_FIREBASE_PROJECT_ID=orignagta-dev npx playwright test pw-flow-smoke-home-profile.spec.ts --project=chromium
 */

import { test, expect } from '@playwright/test';
import { waitForFlutter, hasSemanticLabel } from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://localhost:5005';
const EXPECT_FIREBASE_PROJECT_ID = process.env.E2E_EXPECT_FIREBASE_PROJECT_ID;

async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${TARGET_URL}/`).catch(() => null);
  const status = res?.status?.();
  if (!status || status < 200 || status >= 400) {
    test.skip(true, `Target not reachable at ${TARGET_URL} (status: ${status ?? 'ERR'})`);
  }
}

test.describe('PW Flow — Smoke Home + Profile', () => {
  test.setTimeout(120_000);

  test('Home → cart → product (if any) → scroll → settings/profile', async ({ page, request }) => {
    await requireWebApp(request);

    const expectProjectId = EXPECT_FIREBASE_PROJECT_ID?.trim();
    const expectProjectIdEncoded = expectProjectId ? encodeURIComponent(expectProjectId) : undefined;
    const projectProbe = expectProjectId
      ? page
          .waitForEvent('request', {
            predicate: (req) => {
              const url = req.url();
              if (url.includes(expectProjectId)) return true;
              if (expectProjectIdEncoded && url.includes(expectProjectIdEncoded)) return true;
              const body = req.postData() ?? '';
              if (body.includes(expectProjectId)) return true;
              if (expectProjectIdEncoded && body.includes(expectProjectIdEncoded)) return true;
              return false;
            },
            timeout: 25_000,
          })
          .catch(() => null)
      : Promise.resolve(null);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    const semanticsCount = await page.locator('flt-semantics').count();
    if (semanticsCount === 0) {
      test.skip(true, 'No <flt-semantics> — run against a debug build with ensureSemantics().');
    }

    // CART: best-effort open, then go back.
    const cartBtn = page.getByRole('button', { name: /cart|shopping|panier/i }).first();
    if (await cartBtn.isVisible().catch(() => false)) {
      await cartBtn.click();
      await expect(page).toHaveURL(/\/cart(?:\b|\/|\?|#|$)/i, { timeout: 15_000 }).catch(() => {});
      await page.goBack().catch(() => {});
      await waitForFlutter(page, 60_000);
    }

    // PRODUCT: if any product-card-* exists, click first and go back.
    const productCards = page.locator('[aria-label^="product-card-"]');
    if ((await productCards.count()) > 0) {
      await productCards.first().click();
      await page.waitForTimeout(1200);
      await page.goBack().catch(() => {});
      await waitForFlutter(page, 60_000);
    }

    // SCROLL: best-effort (doesn't need assertions, just exercise the UI).
    await page.mouse.wheel(0, 900);
    await page.waitForTimeout(300);
    await page.mouse.wheel(0, -900);
    await page.waitForTimeout(300);

    // SETTINGS: either navigates to /profile (logged-in) OR shows login prompt.
    const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
    await expect(settingsBtn).toBeAttached();
    await settingsBtn.click();

    const loginCancel = page.getByRole('button', { name: /cancel|annuler/i }).first();
    const loginSignIn = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();

    const openedVia = await Promise.race([
      page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 12_000 }).then(() => 'profile-route' as const),
      loginSignIn.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
      loginCancel.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
    ]).catch(() => null);
    expect(openedVia).toBeTruthy();

    if (openedVia === 'profile-route') {
      // Profile menu should expose stable semantic labels (non-localized).
      const hasOrders = await hasSemanticLabel(page, 'menu-my-orders');
      expect(hasOrders).toBeTruthy();

      // Return home.
      await page.goBack().catch(() => {});
      await waitForFlutter(page, 60_000);
    } else {
      // Close prompt for stability.
      await loginCancel.click().catch(() => page.keyboard.press('Escape'));
    }

    if (expectProjectId) {
      const matched = await projectProbe;
      expect(matched, `Expected a request mentioning Firebase projectId "${expectProjectId}".`).toBeTruthy();
    }
  });
});
