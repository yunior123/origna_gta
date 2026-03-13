import { expect, test, Page, Locator } from '@playwright/test';
import {
  TEST_ACCOUNTS,
  DEFAULT_PASS,
  WEB_APP_URL,
  listCollection,
  setOrignaBaseUserEmailVerified,
  setOrignaBaseUserSuspended,
  setOrignaBaseUserTermsVersion,
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
  await clearServiceWorkers(page);
  await page.goto(`${TARGET_URL}/login`, { waitUntil: 'domcontentloaded' });
  await waitForFlutter(page, 120000);

  const emailInput = page.locator(
    'input[aria-label="you@example.com"], input[aria-label="login_email_field"]',
  ).last();
  await replaceFlutterInputValue(page, emailInput, email);

  const passInput = page.locator(
    'input[aria-label="••••••••"], input[aria-label="login_password_field"]',
  ).last();
  await replaceFlutterInputValue(page, passInput, password);

  const submitBtn = page.locator('[aria-label="login_submit_button"]').first();
  await submitBtn.click({ force: true });
  await page.waitForTimeout(2000);
  await waitForFlutter(page, 60000);
}

test.describe('Auth Gates', () => {
  test.describe.configure({ mode: 'serial' });
  test.setTimeout(300_000);

  test('unverified users are blocked by the email verification gate', async ({ page }) => {
    const email = TEST_ACCOUNTS.BUYER3_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, false);

    try {
      await requireWebApp(page, TARGET_URL);
      await loginViaUi(page, email, DEFAULT_PASS);

      await expect(
        page.getByText(/verify.*email|email.*verification|vérif/i).first(),
      ).toBeVisible({ timeout: 60000 });
      await expect(
        page.getByRole('button', { name: /resend|renvoyer|send again/i }).first(),
      ).toBeVisible({ timeout: 30000 });
    } finally {
      await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    }
  });

  test('outdated terms version forces the terms-update gate', async ({ page }) => {
    const email = TEST_ACCOUNTS.BUYER2_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    await setOrignaBaseUserTermsVersion(email, DEFAULT_PASS, '0.9');

    try {
      await requireWebApp(page, TARGET_URL);
      await loginViaUi(page, email, DEFAULT_PASS);

      await expect(
        page.getByText(/terms.*updated|updated.*terms|conditions.*mise/i).first(),
      ).toBeVisible({ timeout: 60000 });
      await expect(
        page.locator('[aria-label="btn-terms-accept"]').first(),
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

      const settingsBtn = page.locator(`[aria-label="${BTN_SETTINGS_LABEL}"]`).first();
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
    const products = await listCollection('products');
    const withSlug = products.find(product => typeof product?.slug === 'string' && product.slug.length > 0);
    expect(withSlug, 'Expected at least one product with a public slug').toBeTruthy();

    await requireWebApp(page, TARGET_URL);
    await page.goto(`${TARGET_URL}/p/${encodeURIComponent(withSlug.slug)}`, {
      waitUntil: 'domcontentloaded',
    });
    await waitForFlutter(page, 120000);

    await expect(page).toHaveURL(new RegExp(`/p/${withSlug.slug.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`));
    await expect(
      page.getByText(new RegExp(String(withSlug.name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i')).first(),
    ).toBeVisible({ timeout: 60000 });
  });
});
