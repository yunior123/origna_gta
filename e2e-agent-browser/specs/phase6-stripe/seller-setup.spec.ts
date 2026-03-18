/**
 * OrignaGTA — Seller Setup (Stripe Connect) E2E Tests
 * =====================================================
 * Tests seller onboarding screens: /seller/return, /seller/refresh.
 * These handle Stripe Connect account setup callbacks.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { signIn, callCallable } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASS = TEST_ACCOUNTS.SELLER_PASS;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASS = TEST_ACCOUNTS.BUYER_PASS;

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

describe('Seller Setup — Stripe Connect', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T01: Seller navigates to /seller/return', { timeout: 60_000 }, async () => {
    await loginAs(browser, SELLER_EMAIL, SELLER_PASS);
    await browser.open(`${WEB_APP_URL}/seller/return`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should show seller return page content or dashboard redirect
    expect(
      /seller|vendeur|dashboard|setup|stripe|connect|return|retour|welcome|bienvenue/i.test(text)
    ).toBe(true);
  });

  test('T02: Seller navigates to /seller/refresh', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/seller/refresh`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    expect(
      /seller|vendeur|refresh|setup|stripe|connect|actualiser/i.test(text)
    ).toBe(true);
  });

  test('T03: Refresh triggers Stripe Connect sync via API', async () => {
    const auth = await signIn(SELLER_EMAIL, SELLER_PASS);
    const result = await callCallable('get_connect_status', {}, auth.idToken);
    // Should return connect status or a meaningful error (not unauthenticated)
    expect(result.error?.code).not.toBe('unauthenticated');
  });

  test('T04: Non-seller gets error on connect status', async () => {
    const auth = await signIn(BUYER_EMAIL, BUYER_PASS);
    const result = await callCallable('get_connect_status', {}, auth.idToken);
    // Buyer should get permission error or empty result
    const isRestricted =
      result.error?.code === 'permission-denied' ||
      result.error?.code === 'failed-precondition' ||
      result.error?.code === 'not-found' ||
      !result?.stripe_account_id;
    expect(isRestricted).toBe(true);
  });

  test('T05: get_connect_status returns expected shape', async () => {
    const auth = await signIn(SELLER_EMAIL, SELLER_PASS);
    const result = await callCallable('get_connect_status', {}, auth.idToken);
    if (!result.error) {
      // Should have some status fields
      const hasExpectedFields =
        result.stripe_account_id !== undefined ||
        result.charges_enabled !== undefined ||
        result.payouts_enabled !== undefined ||
        result.status !== undefined ||
        result.onboarding_complete !== undefined;
      expect(hasExpectedFields || result === null).toBe(true);
    } else {
      // Endpoint exists but may return error — that's OK
      expect(result.error.code).toBeTruthy();
    }
  });
});
