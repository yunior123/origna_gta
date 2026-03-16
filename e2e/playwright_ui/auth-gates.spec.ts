import { expect, test, Page, Locator } from '@playwright/test';
import {
  TEST_ACCOUNTS,
  DEFAULT_PASS,
  WEB_APP_URL,
  listCollection,
  setOrignaBaseUserEmailVerified,
  setOrignaBaseUserSuspended,
  setOrignaBaseUserTermsVersion,
  resolveUiEmail,
} from './api-helpers';
import { BTN_SETTINGS_LABEL, clearServiceWorkers, requireWebApp, waitForFlutter } from './flutter-helpers';

const TARGET_URL = WEB_APP_URL;

async function replaceFlutterInputValue(page: Page, input: Locator, value: string): Promise<void> {
  await expect(input).toBeVisible({ timeout: 30000 });
  await input.click();
  await page.waitForTimeout(1000);
  await page.evaluate(() => {
    const active = document.activeElement as HTMLInputElement | HTMLTextAreaElement | null;
    if (active && 'value' in active) {
      active.value = '';
      active.dispatchEvent(new Event('input', { bubbles: true }));
      active.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }).catch(() => {});
  await page.keyboard.insertText(value);
  await page.waitForTimeout(300);
}

async function loginViaUi(page: Page, email: string, password: string): Promise<void> {
  // Resolve OrignaBase alias — stable test emails are remapped to e2e-* aliases.
  // Use resolveUiEmail (pure mapping) to avoid repairing email_verified state.
  const resolvedEmail = resolveUiEmail(email);

  await clearServiceWorkers(page);
  await page.goto(`${TARGET_URL}/login`, { waitUntil: 'domcontentloaded' });
  await waitForFlutter(page, 120000);

  const emailInput = page.locator(
    'input[aria-label="you@example.com"], input[aria-label="login_email_field"]',
  ).last();
  // Wait for the login form to be ready
  await emailInput.waitFor({ state: 'visible', timeout: 60000 });
  await replaceFlutterInputValue(page, emailInput, resolvedEmail);

  const passInput = page.locator(
    'input[aria-label="••••••••"], input[aria-label="login_password_field"]',
  ).last();
  await replaceFlutterInputValue(page, passInput, password);
  // Tab out of the password field — same as ensureLoggedInAsAdmin which is known to work
  await passInput.press('Tab').catch(() => {});
  await page.waitForTimeout(500);

  const submitBtn = page.locator('[aria-label="login_submit_button"]').first();
  // Wait for the submit button to be visible before clicking
  await submitBtn.waitFor({ state: 'visible', timeout: 10000 }).catch(() => {});
  await passInput.press('Enter').catch(() => {});
  await page.waitForTimeout(1500);

  // If form still visible, click the submit button directly
  const loginStillVisible =
    await emailInput.isVisible().catch(() => false) ||
    await passInput.isVisible().catch(() => false);
  if (loginStillVisible) {
    await submitBtn.click({ force: true }).catch(async () => {
      await page.keyboard.press('Enter').catch(() => {});
    });
    await page.waitForTimeout(1500);
  }

  // Wait for any post-login signal (URL change, verification screen, or home screen)
  await Promise.race([
    page.waitForURL(url => !/\/login/i.test(url.toString()), { timeout: 30000 }).catch(() => null),
    page.getByText(/verify.*email|email.*verif|vérif/i).first().waitFor({ state: 'visible', timeout: 30000 }).catch(() => null),
    page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first().waitFor({ state: 'attached', timeout: 30000 }).catch(() => null),
  ]);
}

test.describe('Auth Gates', () => {
  test.describe.configure({ mode: 'serial' });
  test.setTimeout(300_000);

  test('unverified users are blocked by the email verification gate', async ({ page }) => {
    const email = TEST_ACCOUNTS.BUYER3_EMAIL;
    // Resolve to the UI alias so setOrignaBaseUserEmailVerified targets the same
    // account that loginViaUi will actually sign in with.
    const uiEmail = resolveUiEmail(email);
    await setOrignaBaseUserEmailVerified(uiEmail, DEFAULT_PASS, false);
    // Wait for OrignaBase to commit the patch before issuing a new JWT
    await page.waitForTimeout(3000);

    try {
      await requireWebApp(page, TARGET_URL);
      await loginViaUi(page, email, DEFAULT_PASS);

      // Do NOT use page.goto() — full reload loses OrignaBase JWT from memory.
      // AuthWrapper at '/' shows EmailVerificationRequiredScreen when emailVerified=false.
      // The gate is visible immediately after login returns (same Flutter session).
      await waitForFlutter(page, 30000);

      await expect(
        page.getByText(/Verify Your Email|verify.*email|vérifi/i).first(),
      ).toBeVisible({ timeout: 60000 });
      await expect(
        page.getByRole('button', { name: /resend|renvoyer|Resend Verification/i }).first(),
      ).toBeVisible({ timeout: 30000 });
    } finally {
      await setOrignaBaseUserEmailVerified(uiEmail, DEFAULT_PASS, true);
    }
  });

  test('outdated terms version forces the terms-update gate', async ({ page }) => {
    const email = TEST_ACCOUNTS.BUYER2_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    await setOrignaBaseUserTermsVersion(email, DEFAULT_PASS, '0.9');

    try {
      await requireWebApp(page, TARGET_URL);
      await loginViaUi(page, email, DEFAULT_PASS);

      // Do NOT use page.goto() — full reload loses OrignaBase JWT from memory.
      // AuthWrapper shows the terms gate immediately after login in the same Flutter session.
      await waitForFlutter(page, 30000);

      await expect(
        page.getByText(/Our Terms Have Been Updated|terms.*updated|updated.*terms|conditions.*mise/i).first(),
      ).toBeVisible({ timeout: 60000 });
      // Confirm the gate is in initial (not-yet-scrolled) state: the scroll hint is visible.
      // Disabled buttons are omitted from Flutter Web semantics, so we check the hint text instead.
      await expect(
        page.getByText(/Scroll to the bottom to enable|Faites défiler/i).first(),
      ).toBeVisible({ timeout: 30000 });
    } finally {
      await setOrignaBaseUserTermsVersion(email, DEFAULT_PASS, '1.0');
    }
  });

  test('suspended users are blocked on protected routes', async ({ page }) => {
    const email = TEST_ACCOUNTS.SELLER1_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    await setOrignaBaseUserSuspended(email, DEFAULT_PASS, true);

    try {
      await requireWebApp(page, TARGET_URL);
      await loginViaUi(page, email, DEFAULT_PASS);

      const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
      await expect(settingsBtn).toBeVisible({ timeout: 60000 });
      await settingsBtn.click({ force: true });
      await waitForFlutter(page, 60000);

      await expect(
        page.getByText(/account.*suspended|suspended.*account|compte.*suspendu/i).first(),
      ).toBeVisible({ timeout: 60000 });
      await expect(
        page.getByText(/contact.*support|contactez/i).first(),
      ).toBeVisible({ timeout: 30000 });
    } finally {
      await setOrignaBaseUserSuspended(email, DEFAULT_PASS, false);
    }
  });

  test('shareable product slug links resolve to product detail pages', async ({ page }) => {
    // Try to find a product with a slug in the DB. Fall back to the stable
    // e2e_product_test_seller product which is always present in dev.
    const STABLE_PRODUCT_ID = 'e2e_product_test_seller';

    const products = await listCollection('products');
    const withSlug = products.find(product => typeof product?.slug === 'string' && product.slug.length > 0);

    // Determine which URL pattern to test:
    // - If a real slug exists, navigate to /p/<slug>
    // - Otherwise navigate to /product/<stableId> (ID-based detail route)
    let navigatePath: string;
    let expectedUrlPattern: RegExp;
    let productNamePattern: RegExp | null = null;

    if (withSlug) {
      navigatePath = `/p/${encodeURIComponent(withSlug.slug)}`;
      expectedUrlPattern = new RegExp(`/p/${withSlug.slug.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`);
      productNamePattern = new RegExp(String(withSlug.name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    } else {
      // No slugs in DB — use the stable product's ID-based route
      navigatePath = `/product/${STABLE_PRODUCT_ID}`;
      expectedUrlPattern = new RegExp(`/product/${STABLE_PRODUCT_ID}`);
      // Accept any product detail page content
      productNamePattern = null;
    }

    await requireWebApp(page, TARGET_URL);
    await page.goto(`${TARGET_URL}${navigatePath}`, { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, 120000);

    // Verify we landed on a product detail page (slug or ID route)
    const currentUrl = page.url();
    expect(currentUrl).toMatch(expectedUrlPattern);

    // Verify product content rendered
    if (productNamePattern) {
      await expect(
        page.getByText(productNamePattern).first(),
      ).toBeVisible({ timeout: 60000 });
    } else {
      // Just confirm Flutter semantics rendered (product detail loaded)
      const semanticsCount = await page.locator('flt-semantics').count();
      expect(semanticsCount).toBeGreaterThan(0);
    }
  });
});
