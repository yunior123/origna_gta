/**
 * Home Smoke (Flutter Web Semantics)
 *
 * Minimal UI smoke test:
 *   - waits for Flutter to boot (flt-glass-pane)
 *   - waits for splash to disappear
 *   - asserts the first screen after splash is Home
 *   - interacts using semantic locators (getByRole / getByLabel)
 *
 * Requires:
 *   - A deployed Flutter Web app (default: https://orignagta.ca)
 *
 * Run:
 *   cd e2e && E2E_TARGET_URL=https://orignagta.ca npx playwright test home-smoke-semantics.spec.ts --project=chromium
 *
 * Debug (local) + force DEV Firebase (no emulators):
 *   cd origna_gta && flutter run -d chrome --web-port=5005 --dart-define=ENVIRONMENT=dev --dart-define=USE_EMULATORS=false
 *   cd e2e && E2E_TARGET_URL=http://localhost:5005 E2E_EXPECT_FIREBASE_PROJECT_ID=orignagta-dev npx playwright test home-smoke-semantics.spec.ts --project=chromium
 */

import { test, expect } from '@playwright/test';
import { waitForFlutter } from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://orignagta.ca';
const EXPECT_FIREBASE_PROJECT_ID = process.env.E2E_EXPECT_FIREBASE_PROJECT_ID;
const FORCE_GUEST = process.env.E2E_FORCE_GUEST === '1' || process.env.E2E_FORCE_GUEST === 'true';

async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${TARGET_URL}/`).catch(() => null);
  const status = res?.status?.();
  if (!status || status < 200 || status >= 400) {
    test.skip(true, `Target not reachable at ${TARGET_URL} (status: ${status ?? 'ERR'})`);
  }
}

test.describe('Home — smoke via semantics', () => {
  test.setTimeout(90_000);

  test('After splash, home is visible and accessible', async ({ page, request }) => {
    await requireWebApp(request);

    const expectProjectId = EXPECT_FIREBASE_PROJECT_ID?.trim();
    const expectProjectIdEncoded = expectProjectId ? encodeURIComponent(expectProjectId) : undefined;
    const projectProbe = expectProjectId
      ? page.waitForEvent('request', {
          predicate: (req) => {
            const url = req.url();
            if (url.includes(expectProjectId)) return true;
            if (expectProjectIdEncoded && url.includes(expectProjectIdEncoded)) return true;
            // Some Firebase endpoints include `projects/{id}` in the body.
            const body = req.postData() ?? '';
            if (body.includes(expectProjectId)) return true;
            if (expectProjectIdEncoded && body.includes(expectProjectIdEncoded)) return true;
            return false;
          },
          timeout: 20_000,
        })
        .catch(() => null)
      : Promise.resolve(null);

    // Flutter Web uses hash routing; Home after splash is expected at /#/.
    // App uses path URL strategy (no #) in main.dart; Home after splash is expected at /.
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);

    if (FORCE_GUEST) {
      // Firebase Auth persistence on web is typically IndexedDB-based.
      // For a visual demo (headed), we want to guarantee the Settings tap opens the login prompt.
      await page.context().clearCookies().catch(() => {});
      await page.evaluate(async () => {
        try { localStorage.clear(); } catch {}
        try { sessionStorage.clear(); } catch {}

        // Best-effort wipe of IndexedDB (works in Chromium). This will sign out Firebase Auth.
        try {
          // @ts-ignore
          const dbs = (indexedDB.databases ? await indexedDB.databases() : []) as any[];
          for (const db of dbs) {
            if (db && db.name) {
              indexedDB.deleteDatabase(db.name);
            }
          }
        } catch {}
      });

      await page.reload();
      await waitForFlutter(page);
    }

    // Flutter host (may be nested; Playwright CSS selectors pierce open shadow DOM by default).
    await expect(page.locator('flt-glass-pane').first()).toBeAttached();

    // If the target build doesn't expose Flutter Web semantics (common in some release builds),
    // we can't use getByRole/getByLabel reliably.
    const semanticsCount = await page.locator('flt-semantics').count();
    if (semanticsCount === 0) {
      test.skip(
        true,
        `No <flt-semantics> found on ${TARGET_URL}. If this is prod/release, run a debug web build locally and point E2E_TARGET_URL to http://localhost:5005 instead.`,
      );
    }

    // Home search field:
    // - In debug/dev builds we usually have a technical semantics label: input-home-search
    // - In some builds only the user-facing label exists (Search/Rechercher)
    // Prefer getByRole/getByLabel first; use aria-label technical ID only as fallback.
    const searchByRole = page.getByRole('textbox', { name: /search|rechercher/i }).first();
    const searchByLabel = page.getByLabel(/search|rechercher/i).first();
    const searchSemanticWrapper = page.locator('[aria-label="input-home-search"]').first();
    const searchNestedInput = searchSemanticWrapper.locator('input').first();

    const searchInput = searchByRole.or(searchByLabel).or(searchNestedInput);

    try {
      await expect(searchInput).toBeVisible({ timeout: 20_000 });
    } catch (e) {
      // Diagnostics: if the technical label is missing, log a small sample of aria-labels.
      const hasTechLabel = (await searchSemanticWrapper.count()) > 0;
      const sampleLabels = await page
        .locator('flt-semantics[aria-label]')
        .evaluateAll((nodes) => {
          const labels = nodes
            .map((n) => (n as HTMLElement).getAttribute('aria-label') || '')
            .filter(Boolean);
          const uniq: string[] = [];
          for (const l of labels) {
            if (!uniq.includes(l)) uniq.push(l);
            if (uniq.length >= 25) break;
          }
          return uniq;
        })
        .catch(() => [] as string[]);

      console.log('ℹ️ Home search not found via role/label within 20s');
      console.log(`ℹ️ Has technical aria-label input-home-search: ${hasTechLabel}`);
      console.log(`ℹ️ Sample semantics aria-labels (up to 25): ${JSON.stringify(sampleLabels)}`);
      throw e;
    }

    await searchInput.click();
    await searchInput.fill('smoke');

    // AppBar actions should be reachable by role (tooltip → aria-label).
    // Keep these permissive: tooltips are localized.
    const settingsBtn = page.getByRole('button', { name: /settings|param(è|e)tres|preferences/i }).first();
    await expect(settingsBtn).toBeAttached();
    await expect(page.getByRole('button', { name: /cart|shopping|panier/i }).first()).toBeAttached();

    // Tap Settings.
    // Home Settings button behavior (Flutter):
    // - if user is logged in: Navigator.pushNamed(AppRoutes.profile) → URL contains /profile
    // - else: showLoginPrompt() AlertDialog → buttons Cancel / Sign In
    await settingsBtn.click();

    const loginCancel = page.getByRole('button', { name: /cancel|annuler/i }).first();
    const loginSignIn = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();

    const openedVia = await Promise.race(
      FORCE_GUEST
        ? [
            loginSignIn.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
            loginCancel.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
          ]
        : [
            page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 12_000 }).then(() => 'profile-route' as const),
            loginSignIn.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
            loginCancel.waitFor({ state: 'visible', timeout: 12_000 }).then(() => 'login-prompt' as const),
          ],
    ).catch(() => null);

    expect(
      openedVia,
      FORCE_GUEST
        ? 'Expected login prompt after clicking Settings (E2E_FORCE_GUEST enabled).'
        : 'Expected either navigation to /profile or a login prompt after clicking Settings.',
    ).toBeTruthy();

    // Best-effort close dialog if it opened (keeps test stable for future steps).
    if (openedVia === 'login-prompt') {
      await loginCancel.click().catch(() => page.keyboard.press('Escape'));
    }

    if (expectProjectId) {
      const matched = await projectProbe;
      expect(
        matched,
        `Expected at least one network request mentioning Firebase projectId "${expectProjectId}". Make sure you started Flutter with --dart-define=ENVIRONMENT=dev and --dart-define=USE_EMULATORS=false.`,
      ).toBeTruthy();
    }
  });
});
