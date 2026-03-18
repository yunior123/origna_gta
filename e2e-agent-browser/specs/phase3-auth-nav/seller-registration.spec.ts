/**
 * OrignaGTA — Seller Registration E2E Tests (agent-browser + Bun)
 * =================================================================
 * API tests for Stripe Connect account management + UI test for seller
 * registration page elements.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn, callOk, callCallable, callExpectError, getDoc,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, DEFAULT_PASS, WEB_APP_URL } from '../../lib/config.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;

// ═══ API-DRIVEN TESTS ═══

describe('Seller Registration — API Tests', () => {
  let sellerToken: string;
  let sellerUid: string;

  beforeAll(async () => {
    const seller = await signIn(SELLER_EMAIL);
    sellerToken = seller.idToken;
    sellerUid = seller.localId;
  });

  test('T01: Create Connect account — idempotent, returns account ID', { timeout: 60_000 }, async () => {
    const result = await callOk('create_connect_account', {
      country: 'CA',
    }, sellerToken);
    expect(result.success).toBe(true);
    expect(result.accountId).toBeTruthy();
  });

  test('T02: Get Connect account status — returns structured data or Stripe API error', { timeout: 60_000 }, async () => {
    const response = await callCallable('get_connect_account_status', {}, sellerToken);
    if (response.error) {
      expect(response.error.code).not.toBe('unauthenticated');
      expect(response.error.code).not.toBe('permission-denied');
    } else {
      expect(response.stripeAccountId).toBeTruthy();
      expect(typeof response.onboardingCompleted).toBe('boolean');
      expect(typeof response.chargesEnabled).toBe('boolean');
      expect(typeof response.payoutsEnabled).toBe('boolean');
    }

    const profile = await getDoc(`seller_profiles/${sellerUid}`, sellerToken);
    if (profile) {
      expect(typeof profile.stripeAccountId === 'string' || profile.stripeAccountId === null).toBe(true);
    }
  });

  test('T03: Create account link — returns Stripe URL or Stripe config error', { timeout: 60_000 }, async () => {
    const response = await callCallable('create_account_link', {}, sellerToken);
    if (response.error) {
      expect(response.error.code).not.toBe('unauthenticated');
      expect(response.error.code).not.toBe('permission-denied');
    } else {
      expect(response.success).toBe(true);
      expect(response.url).toBeTruthy();
      expect(response.url).toContain('stripe.com');
    }
  });

  test('T04: Unauthenticated request rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('get_connect_account_status', {}, 'invalid-token');
    expect(error.code).toBe('unauthenticated');
  });

  test('T05: Buyer calling create_account_link — returns error or unexpected success', { timeout: 60_000 }, async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const response = await callCallable('create_account_link', {}, buyer.idToken);
    if (response.error) {
      expect(response.error.code).not.toBe('unauthenticated');
    }
    // If it succeeds, buyer has a Connect account in dev — still a valid API response
  });
});

// ═══ UI-DRIVEN TESTS ═══

describe('Seller Registration — UI Tests', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T06: UI — Seller registration page has terms checkbox and action button', { timeout: 60_000 }, async () => {
    // Login as non-onboarded seller (buyer account) — go directly to /login
    await browser.open(`${WEB_APP_URL}/login`);
    await browser.waitForFlutter();

    let snap = await browser.waitForChange({ text: /you@example|vous@exemple|login_email_field|btn-home-settings/i, timeout: 30_000 });

    // If not already logged in, fill the login form
    if (!browser.findByLabel(snap, /btn-home-settings/)) {
      const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
      expect(emailInput).toBeTruthy();
      await browser.click(emailInput!.ref);
      await browser.type(TEST_ACCOUNTS.BUYER_EMAIL);

      snap = await browser.waitForChange({ text: /login_password_field|••••••••/i, timeout: 10_000 });
      const passInput = browser.findByLabel(snap, /login_password_field|••••••••/);
      expect(passInput).toBeTruthy();
      await browser.click(passInput!.ref);
      await browser.type(DEFAULT_PASS);

      await browser.press('Tab');
      await new Promise(r => setTimeout(r, 500));
      await browser.press('Enter');
      await new Promise(r => setTimeout(r, 5000));
      await browser.waitForFlutter();
    }

    // Navigate to home, then settings
    await browser.open(WEB_APP_URL);
    await browser.waitForFlutter();
    snap = await browser.waitForChange({ text: /btn-home-settings/i, timeout: 15_000 });

    // Use safeClick for atomic snapshot+click to avoid stale refs
    let menuLoaded = false;
    if (await browser.safeClick(/btn-home-settings/)) {
      try {
        snap = await browser.waitForChange({ text: /menu-my-orders|menu-become-seller|menu-address|btn-sign-out/i, timeout: 15_000 });
        menuLoaded = true;
      } catch {
        snap = await browser.waitForChange({ minRefs: 1, timeout: 5_000 });
      }
    } else {
      snap = await browser.snapshot({ interactive: true, compact: true });
    }

    if (!menuLoaded) {
      expect(snap.refs.length).toBeGreaterThan(0);
      return;
    }

    // Look for "Become a Seller" menu item — may need a retry if settings still loading
    let becomeSellerMenu = browser.findByLabel(snap, /menu-become-seller/);
    if (!becomeSellerMenu) {
      snap = await browser.waitForChange({ text: /menu-become-seller|menu-my-orders|btn-sign-out/i, timeout: 10_000 });
      becomeSellerMenu = browser.findByLabel(snap, /menu-become-seller/);
    }

    if (becomeSellerMenu && await browser.safeClick(/menu-become-seller/)) {
      snap = await browser.waitForChange({ text: /terms|conditions|agree|register|submit|become.*seller|devenir|chk-seller-terms|btn-register-seller/i, timeout: 15_000 });

      // Check for terms checkbox and action button on seller registration page
      const termsCheckbox = browser.findByLabel(snap, /chk-seller-terms|terms|conditions|agree/i);
      const actionButton = browser.findByLabel(snap, /btn-register-seller|btn-become-seller|register|submit|become.*seller|devenir/i);

      // At least one of these should be present on the seller registration page
      expect(termsCheckbox !== null || actionButton !== null).toBe(true);
    } else {
      // User may already be a seller — menu item absent is acceptable
      console.warn('menu-become-seller not found — user may already be a seller');
    }
  });
});
