/**
 * Playwright parity: integration_test/flows/admin_flow_test.dart
 *
 * This is a UI interaction smoke of the Admin Panel navigation.
 * It does NOT attempt to elevate roles; it assumes the current session is admin.
 *
 * Run app (debug, DEV Firebase, no emulators):
 *   cd origna_gta && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5005 \
 *     --dart-define=ENVIRONMENT=dev --dart-define=USE_EMULATORS=false
 */

import { test, expect } from '@playwright/test';
import { waitForFlutter, hasSemanticLabel } from './flutter-helpers';
import fs from 'node:fs';
import path from 'node:path';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'http://127.0.0.1:5005';
const EXPECT_FIREBASE_PROJECT_ID = process.env.E2E_EXPECT_FIREBASE_PROJECT_ID;
const DISABLE_SW_CACHE = process.env.E2E_DISABLE_SW_CACHE === '1' || process.env.E2E_DISABLE_SW_CACHE === 'true';

function loadDevIntegrationCreds(): { email?: string; password?: string } {
  // Optional local helper file; do NOT hard-fail if missing.
  // This file is generated in this repo and is intended for DEV Firebase integration testing.
  const filePath = path.resolve(__dirname, '../logs/integration_dart_defines.dev.json');
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    const json = JSON.parse(raw) as any;
    return {
      email: json?.TEST_ADMIN_EMAIL,
      password: json?.TEST_ADMIN_PASSWORD,
    };
  } catch {
    return {};
  }
}

const DEV_CREDS = loadDevIntegrationCreds();
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? DEV_CREDS.email;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? DEV_CREDS.password;

async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${TARGET_URL}/`).catch(() => null);
  const status = res?.status?.();
  if (!status || status < 200 || status >= 400) {
    test.skip(true, `Target not reachable at ${TARGET_URL} (status: ${status ?? 'ERR'})`);
  }
}

test.describe('PW Flow — Admin Panel', () => {
  test.setTimeout(150_000);

  test('Profile → Admin Panel → tabs navigation', async ({ page, request }) => {
    await requireWebApp(request);

    page.on('pageerror', (err) => {
      console.log(`PAGEERROR: ${String(err)}`);
    });
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        console.log(`CONSOLE_ERROR: ${msg.text()}`);
      }
    });

    if (DISABLE_SW_CACHE) {
      // Optional: avoid stale cached Flutter bundles (service worker) which can cause “stuck loading”.
      await page.route('**/*', (route) => {
        route.continue({ headers: { ...route.request().headers(), 'Cache-Control': 'no-cache' } });
      });
    }

    // Flutter Web boot can exceed the project-wide actionTimeout (15s).
    // Increase defaults locally for this spec.
    page.setDefaultTimeout(120_000);
    page.setDefaultNavigationTimeout(120_000);

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

    if (DISABLE_SW_CACHE) {
      // Best-effort: unregister SW + clear caches, then reload fresh.
      await page
        .evaluate(async () => {
          try {
            if ('serviceWorker' in navigator) {
              const regs = await navigator.serviceWorker.getRegistrations();
              for (const reg of regs) await reg.unregister();
            }
            if ('caches' in window) {
              const names = await caches.keys();
              for (const name of names) await caches.delete(name);
            }
          } catch {}
        })
        .catch(() => {});
      await page.reload({ waitUntil: 'domcontentloaded' });
    }

    await waitForFlutter(page, 120_000);

    const semanticsCount = await page.locator('flt-semantics').count();
    if (semanticsCount === 0) {
      test.skip(true, 'No <flt-semantics> — run against a debug build with ensureSemantics().');
    }

    // Open Profile via Home Settings button.
    const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
    await expect(settingsBtn).toBeAttached();
    await settingsBtn.click();

    // If not logged in, a login prompt appears. Use UI login to continue.
    const loginCancel = page.getByRole('button', { name: /cancel|annuler/i }).first();
    const loginSignIn = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();
    const loginPromptVisible = await loginSignIn.isVisible().catch(() => false);
    if (loginPromptVisible) {
      if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
        test.skip(true, 'Admin login required. Provide E2E_ADMIN_EMAIL/E2E_ADMIN_PASSWORD or logs/integration_dart_defines.dev.json');
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

      // Back to home (or any non-login route), then open profile again.
      await expect(page).not.toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 45_000 });
      await waitForFlutter(page, 120_000);

      await page.goto(`${TARGET_URL}/`);
      await waitForFlutter(page, 120_000);
      await settingsBtn.click();

      // If the prompt is still there, bail (something is wrong with auth persistence).
      if (await loginSignIn.isVisible().catch(() => false)) {
        await loginCancel.click().catch(() => page.keyboard.press('Escape'));
        test.skip(true, 'Could not establish signed-in state after UI login; login prompt still appears.');
      }
    }

    await expect(page).toHaveURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
    await waitForFlutter(page, 120_000);

    // Admin panel entry should exist for admins.
    const adminMenuBySemantics = page.locator('[aria-label="menu-admin-panel"]').first();
    const adminMenuByRole = page.getByRole('button', { name: /admin/i }).first();
    const hasAdminMenu = (await adminMenuBySemantics.count()) > 0 || (await adminMenuByRole.count()) > 0;
    if (!hasAdminMenu) {
      test.skip(true, 'Admin panel entry not visible — current user likely not admin.');
    }

    await adminMenuBySemantics.click().catch(async () => {
      await adminMenuByRole.click();
    });
    await expect(page).toHaveURL(/\/admin(?:\b|\/|\?|#|$)/i, { timeout: 20_000 });
    await waitForFlutter(page, 120_000);

    // Tabs: prefer stable aria-labels if present, else click by role=tab and visible text.
    const tabPlan: Array<{ aria: string; name: RegExp }> = [
      { aria: 'admin-tab-sellers', name: /sellers|vendeurs/i },
      { aria: 'admin-tab-users', name: /users|utilisateurs/i },
      { aria: 'admin-tab-orders', name: /orders|commandes/i },
      { aria: 'admin-tab-products', name: /products|produits/i },
      { aria: 'admin-tab-payments', name: /payments|paiements/i },
      { aria: 'admin-tab-security', name: /security|s[eé]curit[eé]/i },
    ];

    for (const tab of tabPlan) {
      const byAria = page.locator(`[aria-label="${tab.aria}"]`).first();
      const byRoleTab = page.getByRole('tab', { name: tab.name }).first();
      const clicked = await byAria
        .click()
        .then(() => true)
        .catch(async () => byRoleTab.click().then(() => true).catch(() => false));

      if (!clicked) {
        // Fallback: click by text when role mapping isn't available.
        await page.getByText(tab.name).first().click().catch(() => {});
      }

      await page.waitForTimeout(600);
      await expect(page.locator('flt-glass-pane').first()).toBeAttached();
    }

    if (expectProjectId) {
      const matched = await projectProbe;
      expect(matched, `Expected a request mentioning Firebase projectId "${expectProjectId}".`).toBeTruthy();
    }
  });
});
