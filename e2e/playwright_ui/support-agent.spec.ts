/**
 * OrignaGTA — Customer Support Agent E2E Tests
 * ==============================================
 * Tests the AI-powered support chat at /support.
 * Auth-gated: unauthenticated users redirect to /login.
 *
 * Tests:
 *   T01: Unauthenticated user is redirected to login
 *   T02: Authenticated user sees category picker on /support
 *   T03: Selecting a category starts the conversation (shows chat input)
 *   T04: User can type in the chat input
 *   T05: Profile → Get Help navigates to /support
 *
 * Run: cd e2e && npx playwright test playwright_ui/support-agent.spec.ts --config=playwright.config.dev.ts
 */
import { test, expect } from '@playwright/test';
import { TEST_ACCOUNTS, WEB_APP_URL } from './api-helpers';
import {
  waitForFlutter,
  requireWebApp,
  flutterByLabel,
  ensureLoggedInAsAdmin,
} from './flutter-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASS = TEST_ACCOUNTS.BUYER_PASS;

test.describe('Customer Support Agent', () => {
  test.beforeEach(async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
  });

  test('T01 — unauthenticated user redirected to login from /support', async ({ page }) => {
    await page.goto(`${TARGET_URL}/#/support`);
    await waitForFlutter(page);
    // Should end up on login
    await expect(page).toHaveURL(/login/, { timeout: 15000 });
  });

  test('T02 — authenticated buyer sees category picker', async ({ page }) => {
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);
    await page.goto(`${TARGET_URL}/#/support`);
    await waitForFlutter(page);

    // Category picker should be visible
    const orderStatus = flutterByLabel(page, /order status/i);
    await expect(orderStatus).toBeVisible({ timeout: 20000 });
    const refund = flutterByLabel(page, /refund/i);
    await expect(refund).toBeVisible();
    const other = flutterByLabel(page, /other/i);
    await expect(other).toBeVisible();
  });

  test('T03 — selecting category reveals chat input', async ({ page }) => {
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);
    await page.goto(`${TARGET_URL}/#/support`);
    await waitForFlutter(page);

    // Click "Other" category
    const other = flutterByLabel(page, /other/i);
    await expect(other).toBeVisible({ timeout: 20000 });
    await other.click();

    // Chat input should appear (AI response may take up to 30s)
    const input = flutterByLabel(page, 'support-input');
    await expect(input).toBeVisible({ timeout: 35000 });
  });

  test('T04 — user can type and attempt to send message', async ({ page }) => {
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);
    await page.goto(`${TARGET_URL}/#/support`);
    await waitForFlutter(page);

    const other = flutterByLabel(page, /other/i);
    await expect(other).toBeVisible({ timeout: 20000 });
    await other.click();

    const input = flutterByLabel(page, 'support-input');
    await expect(input).toBeVisible({ timeout: 35000 });
    await input.fill('Hello, I have a question.');

    const sendBtn = flutterByLabel(page, 'btn-send-support');
    await expect(sendBtn).toBeVisible();
  });

  test('T05 — Profile → Get Help navigates to support screen', async ({ page }) => {
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);

    // Navigate to profile via settings button (home screen nav)
    await page.goto(`${TARGET_URL}`);
    await waitForFlutter(page);
    const profileNav = page.getByRole('button', { name: 'btn-home-settings' }).first();
    await expect(profileNav).toBeAttached({ timeout: 15000 });
    await profileNav.click();
    await waitForFlutter(page);

    // Find "Get Help" button
    const getHelp = flutterByLabel(page, /get help/i);
    await expect(getHelp).toBeVisible({ timeout: 15000 });
    await getHelp.click();
    await waitForFlutter(page);

    // Should be on support screen with category picker
    const orderStatus = flutterByLabel(page, /order status/i);
    await expect(orderStatus).toBeVisible({ timeout: 20000 });
  });
});
