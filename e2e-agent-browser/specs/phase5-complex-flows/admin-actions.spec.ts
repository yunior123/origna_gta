/**
 * OrignaGTA — Admin Actions E2E Tests (agent-browser)
 * =====================================================
 * Migrated from e2e/playwright_ui/admin-actions.spec.ts
 *
 * Tests admin panel operations: UI access via profile menu,
 * admin-only API endpoints, and non-admin access control.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn,
  callCallable,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  await browser.open(`${WEB_APP_URL}/login`);
  await browser.waitForFlutter();
  let snap = await browser.waitForChange({ text: /you@example|vous@exemple|login_email_field/i, timeout: 30_000 });

  const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
  if (!emailInput) throw new Error('Email input not found');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.waitForChange({ text: /login_password_field|••••••••/i, timeout: 10_000 });
  const passInput = browser.findByLabel(snap, /login_password_field|••••••••/);
  if (!passInput) throw new Error('Password input not found');
  await browser.click(passInput.ref);
  await browser.type(password);

  await browser.press('Tab');
  await new Promise(r => setTimeout(r, 500));
  await browser.press('Enter');
  await new Promise(r => setTimeout(r, 5000));
  await browser.waitForFlutter();
}

describe('Admin Actions', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Admin can access admin panel via profile', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);

    // Navigate to settings/profile
    let snap = await browser.snapshot({ interactive: true, compact: true });
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    if (!settings) throw new Error('Settings button not found');
    await browser.click(settings.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Look for admin panel entry in profile menu
    snap = await browser.snapshot({ interactive: true, compact: true });
    const adminEntry = browser.findByLabel(snap, /admin|panneau|panel/i);

    // Admin should see an admin panel option or be able to navigate to admin
    // If no explicit menu item, try navigating directly
    if (adminEntry) {
      await browser.click(adminEntry.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
    } else {
      await browser.open(`${WEB_APP_URL}/admin`);
      await browser.waitForFlutter();
    }

    snap = await browser.snapshot({ interactive: true, compact: true });

    // Admin panel should show admin tabs
    const adminTab = browser.findByLabel(snap, /admin-tab-users|admin-tab-products|admin-tab-orders|admin-tab-sellers/);
    const adminContent = browser.findByLabel(snap, /admin|gestion|management/i);
    expect(adminTab ?? adminContent).toBeTruthy();
  });

  test('Admin can call admin-only endpoints via API', async () => {
    const auth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callCallable('admin_update_product_stock', {
      productId: 'nonexistent_test',
      newStock: 10,
    }, auth.idToken);

    // Should either succeed or return a business-logic error (not permission-denied)
    if (result.error) {
      const msg = (result.error.message || '').toLowerCase();
      expect(msg).not.toContain('permission');
      expect(msg).not.toContain('unauthenticated');
    }
  });

  test('Non-admin cannot access admin endpoints', async () => {
    const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const result = await callCallable('admin_update_product_stock', {
      productId: 'nonexistent_test',
      newStock: 10,
    }, buyerAuth.idToken);

    expect(result.error).toBeTruthy();
  });
});
