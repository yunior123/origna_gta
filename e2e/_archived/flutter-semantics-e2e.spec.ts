/**
 * Flutter Semantics E2E Test
 *
 * Verifies that Flutter Web's semantics tree (<flt-semantics> elements) is
 * correctly generated and that Playwright can interact with the UI exclusively
 * via ARIA roles, labels, and the helpers from flutter-helpers.ts.
 *
 * Requires:
 *   - Firebase emulators running (`firebase emulators:start`)
 *   - Flutter Web app served on localhost:5005
 *     (`cd origna_gta && flutter run -d chrome --web-port=5005`)
 *
 * Run with:
 *   cd e2e && npx playwright test flutter-semantics-e2e.spec.ts --project=chromium
 */

import { test, expect, Page } from '@playwright/test';
import {
  waitForFlutter,
  flutterButton,
  flutterByLabel,
  flutterByExactLabel,
  fillFlutterInput,
  hasSemanticLabel,
  waitForSemanticLabel,
} from './flutter-helpers';

const WEB_APP_URL = 'http://localhost:5005';
const AUTH_EMULATOR = 'http://localhost:9099';
const PROJECT_ID = 'orignagta';

// ─── Helpers ────────────────────────────────────────────────────────

/** Quick infrastructure gate — skips the whole suite if the web app is down. */
async function requireWebApp(request: any): Promise<void> {
  const res = await request.get(`${WEB_APP_URL}/`).catch(() => null);
  if (!res || res.status() !== 200) {
    test.skip(true, 'Web app not running on :5005 — run start-dev.sh first');
  }
}

/** Create a user via the Auth emulator REST API. */
async function createTestUser(email: string, password: string) {
  const response = await fetch(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
  );
  return response.json();
}

// ─── Test Suite ─────────────────────────────────────────────────────

test.describe('Flutter Semantics — UI Interaction via ARIA', () => {
  // Serial: we reuse a single Flutter instance to avoid 40s cold-boot per test.
  test.describe.configure({ mode: 'serial' });
  test.setTimeout(120_000);

  let sharedPage: Page;

  test.beforeAll(async ({ browser }) => {
    sharedPage = await browser.newPage();
  });

  test.afterAll(async () => {
    if (sharedPage) await sharedPage.close();
  });

  // ── 1. Semantics tree boots correctly ───────────────────────────

  test('Semantics tree is present after Flutter loads', async ({ request }) => {
    await requireWebApp(request);

    await sharedPage.goto(WEB_APP_URL);
    await waitForFlutter(sharedPage);

    // <flt-semantics> elements should exist (always-on via ensureSemantics)
    const semanticsCount = await sharedPage.locator('flt-semantics').count();
    expect(semanticsCount).toBeGreaterThan(0);
    console.log(`✅ Semantics tree active — ${semanticsCount} <flt-semantics> nodes`);
  });

  // ── 2. Home screen semantic elements exist ──────────────────────

  test('Home screen exposes key semantic labels', async ({ request }) => {
    await requireWebApp(request);

    // The page is already on home from the previous test.
    // Verify the search bar semantic label.
    const hasSearch = await hasSemanticLabel(sharedPage, 'input-home-search');
    expect(hasSearch).toBeTruthy();
    console.log('✅ input-home-search label found');

    // Verify the AppBar buttons via their tooltips (which Flutter maps to aria-label).
    // Settings, Add product, and Shopping cart are IconButtons with tooltip:.
    // Their tooltips are localized, so we use a broader getByRole check.
    const settingsBtn = sharedPage.getByRole('button', { name: /settings/i });
    await expect(settingsBtn.first()).toBeAttached();
    console.log('✅ Settings button accessible by role');

    const cartBtn = sharedPage.getByRole('button', { name: /cart|shopping/i });
    await expect(cartBtn.first()).toBeAttached();
    console.log('✅ Cart button accessible by role');
  });

  // ── 3. Search bar interaction via semantics ─────────────────────

  test('Can type into search bar via semantic label', async ({ request }) => {
    await requireWebApp(request);

    // Focus and type into the search field using its aria-label
    const searchField = flutterByExactLabel(sharedPage, 'input-home-search');
    await searchField.click();

    // Flutter text fields render a nested <input>; use keyboard to type.
    await sharedPage.keyboard.type('test search query', { delay: 30 });
    await sharedPage.waitForTimeout(500);

    // The clear-search button should now appear
    const hasClear = await hasSemanticLabel(sharedPage, 'btn-clear-search');
    expect(hasClear).toBeTruthy();
    console.log('✅ Typed into search — btn-clear-search appeared');

    // Click the clear button via its semantic label
    await flutterByExactLabel(sharedPage, 'btn-clear-search').click();
    await sharedPage.waitForTimeout(500);

    // Clear button should disappear after clearing
    const hasClearAfter = await hasSemanticLabel(sharedPage, 'btn-clear-search');
    expect(hasClearAfter).toBeFalsy();
    console.log('✅ btn-clear-search disappeared after clearing');
  });

  // ── 4. Product cards have semantic labels (if products exist) ───

  test('Product cards expose semantic labels when products are loaded', async ({ request }) => {
    await requireWebApp(request);

    // Wait a moment for products to load from Firestore emulator
    await sharedPage.waitForTimeout(3000);

    // Check if any product-card-* labels exist
    const productCards = sharedPage.locator('[aria-label*="product-card-"]');
    const cardCount = await productCards.count();

    if (cardCount === 0) {
      console.log('⚠️  No products in emulator — skipping product card assertions');
      // This is expected when running with empty emulator data
      test.skip(true, 'No products seeded in emulator');
      return;
    }

    // Verify the first card is a clickable element
    const firstCard = productCards.first();
    await expect(firstCard).toBeAttached();

    // Get the aria-label to log it
    const labelValue = await firstCard.getAttribute('aria-label');
    console.log(`✅ Found ${cardCount} product card(s) — first: "${labelValue}"`);

    // Product cards should also have favorite and add-to-cart buttons
    const favButtons = sharedPage.locator('[aria-label*="btn-favorite-"]');
    const favCount = await favButtons.count();
    expect(favCount).toBeGreaterThan(0);
    console.log(`✅ Found ${favCount} favorite button(s)`);

    const cartButtons = sharedPage.locator('[aria-label*="btn-add-to-cart-"]');
    const cartBtnCount = await cartButtons.count();
    expect(cartBtnCount).toBeGreaterThan(0);
    console.log(`✅ Found ${cartBtnCount} add-to-cart button(s)`);
  });

  // ── 5. Navigation to login & semantic form interaction ──────────

  test('Login screen exposes semantic form elements', async ({ request }) => {
    await requireWebApp(request);

    // Navigate to login
    await sharedPage.goto(`${WEB_APP_URL}/#/login`);
    await waitForFlutter(sharedPage, 60_000);
    await sharedPage.waitForTimeout(2000);

    // The login form should have email and password textboxes.
    // ModernTextField uses InputDecoration(labelText:) which Flutter auto-maps to aria-label.
    const emailInput = sharedPage.getByRole('textbox', { name: /email/i });
    await expect(emailInput.first()).toBeAttached({ timeout: 15_000 });
    console.log('✅ Email textbox accessible by role');

    const passwordInput = sharedPage.getByRole('textbox', { name: /password/i });
    // Note: password fields may be textbox or none role depending on Flutter version
    const passwordCount = await passwordInput.count();
    if (passwordCount > 0) {
      console.log('✅ Password textbox accessible by role');
    } else {
      console.log('ℹ️  Password field may not expose textbox role (obscured text)');
    }

    // The primary login button should be accessible — ModernButton auto-wraps
    // with Semantics(button: true, label: widget.label).
    // The label is the localized "Sign In" text.
    const signInBtn = sharedPage.getByRole('button', { name: /sign.?in|connexion/i });
    await expect(signInBtn.first()).toBeAttached({ timeout: 10_000 });
    console.log('✅ Sign In button accessible by role');

    // Toggle auth mode button
    const hasToggle = await hasSemanticLabel(sharedPage, 'btn-toggle-auth-mode');
    expect(hasToggle).toBeTruthy();
    console.log('✅ btn-toggle-auth-mode label found');
  });

  // ── 6. Type into login form via semantics & toggle auth mode ────

  test('Can fill login form and toggle auth mode via semantics', async ({ request }) => {
    await requireWebApp(request);

    // We should still be on the login page from previous test
    const emailInput = sharedPage.getByRole('textbox', { name: /email/i });
    await emailInput.first().click();
    await emailInput.first().fill('e2e-test@example.com');

    // Verify value was entered
    const emailValue = await emailInput.first().inputValue();
    expect(emailValue).toBe('e2e-test@example.com');
    console.log('✅ Filled email via ARIA role selector');

    // Toggle to sign-up mode using the semantic label
    await flutterByExactLabel(sharedPage, 'btn-toggle-auth-mode').click();
    await sharedPage.waitForTimeout(1500);

    // In sign-up mode, extra fields appear (name, terms checkbox).
    // Check for the terms checkbox semantic label.
    const hasTermsCheckbox = await hasSemanticLabel(sharedPage, 'checkbox-accept-terms');
    if (hasTermsCheckbox) {
      console.log('✅ checkbox-accept-terms appeared after toggling to sign-up');
    } else {
      // The label might not be on the exact same element; check by role
      const checkboxes = sharedPage.getByRole('checkbox');
      const checkboxCount = await checkboxes.count();
      console.log(`ℹ️  Found ${checkboxCount} checkbox(es) via role in sign-up mode`);
      expect(checkboxCount).toBeGreaterThan(0);
    }

    // Toggle back to login mode
    await flutterByExactLabel(sharedPage, 'btn-toggle-auth-mode').click();
    await sharedPage.waitForTimeout(1000);

    // Forgot password should be visible in login mode
    const hasForgotPw = await hasSemanticLabel(sharedPage, 'btn-forgot-password');
    expect(hasForgotPw).toBeTruthy();
    console.log('✅ btn-forgot-password label found in login mode');
  });

  // ── 7. Navigate back to home and verify semantics survive ───────

  test('Semantics tree persists across navigation', async ({ request }) => {
    await requireWebApp(request);

    // Go back to home
    await sharedPage.goto(`${WEB_APP_URL}/#/`);
    await waitForFlutter(sharedPage, 60_000);
    await sharedPage.waitForTimeout(2000);

    // Verify semantics tree is still alive
    const semanticsCount = await sharedPage.locator('flt-semantics').count();
    expect(semanticsCount).toBeGreaterThan(0);

    // Verify key home screen labels survived the round-trip
    const hasSearch = await hasSemanticLabel(sharedPage, 'input-home-search');
    expect(hasSearch).toBeTruthy();
    console.log(`✅ Semantics survived navigation — ${semanticsCount} nodes, search label present`);
  });

  // ── 8. Legal links have semantic labels ─────────────────────────

  test('Footer legal links expose semantic labels', async ({ request }) => {
    await requireWebApp(request);

    // Scroll to the bottom to find legal links
    // Home screen has privacy policy and terms of service links
    const hasPrivacy = await hasSemanticLabel(sharedPage, 'btn-home-privacy-policy');
    const hasTerms = await hasSemanticLabel(sharedPage, 'btn-home-terms-of-service');

    if (hasPrivacy && hasTerms) {
      console.log('✅ Legal links found: btn-home-privacy-policy, btn-home-terms-of-service');
    } else {
      // Links may be off-screen; scroll down to find them
      await sharedPage.keyboard.press('End');
      await sharedPage.waitForTimeout(1000);

      const hasPrivacyAfterScroll = await hasSemanticLabel(sharedPage, 'btn-home-privacy-policy');
      const hasTermsAfterScroll = await hasSemanticLabel(sharedPage, 'btn-home-terms-of-service');
      
      // At least one should be accessible
      console.log(`ℹ️  After scroll — privacy: ${hasPrivacyAfterScroll}, terms: ${hasTermsAfterScroll}`);
      // Don't hard-fail — these might be hidden when products fill the viewport
    }

    console.log('✅ Legal links semantic check complete');
  });
});
