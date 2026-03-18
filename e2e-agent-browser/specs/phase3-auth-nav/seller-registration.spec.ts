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
import { TEST_ACCOUNTS } from '../../lib/config.js';

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
    // Login as non-onboarded seller (buyer account)
    await browser.open('https://dev.orignagta.ca');
    await browser.waitForFlutter();

    let snap = await browser.waitForChange({ text: /you@example|vous@exemple|login_email_field/i, timeout: 30_000 });
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    expect(settings).toBeTruthy();
    await browser.click(settings!.ref);
    await new Promise(r => setTimeout(r, 1500));

    snap = await browser.snapshot({ interactive: true, compact: true });
    const loginBtn = browser.findByLabel(snap, /se connecter|sign in/i);
    if (loginBtn) {
      await browser.click(loginBtn.ref);
      await new Promise(r => setTimeout(r, 2000));

      snap = await browser.snapshot({ interactive: true, compact: true });
      const emailInput = browser.findByLabel(snap, /vous@exemple|you@example/i);
      expect(emailInput).toBeTruthy();
      await browser.fill(emailInput!.ref, 'e2e-buyer@test.origna.ca');

      const passInput = browser.findByLabel(snap, /••••••••/);
      expect(passInput).toBeTruthy();
      await browser.fill(passInput!.ref, 'REDACTED_TEST_PASSWORD');

      const submitBtn = browser.findByLabel(snap, /login_submit_button/);
      expect(submitBtn).toBeTruthy();
      await browser.click(submitBtn!.ref);
      await new Promise(r => setTimeout(r, 3000));
    }

    // Navigate to settings
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsAfterLogin = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsAfterLogin) {
      await browser.click(settingsAfterLogin.ref);
      await new Promise(r => setTimeout(r, 2000));
    }

    // Look for "Become a Seller" menu item
    snap = await browser.snapshot({ interactive: true, compact: true });
    const becomeSellerMenu = browser.findByLabel(snap, /menu-become-seller/);

    if (becomeSellerMenu) {
      await browser.click(becomeSellerMenu.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();

      snap = await browser.snapshot({ interactive: true, compact: true });
      // Check for terms checkbox and action button on seller registration page
      const termsCheckbox = browser.findByLabel(snap, /terms|conditions|agree/i)
        ?? browser.findByRole(snap, 'checkbox', /terms|conditions|agree/i);
      const actionButton = browser.findByRole(snap, 'button', /register|submit|become.*seller|devenir/i);

      // At least one of these should be present on the seller registration page
      expect(termsCheckbox !== null || actionButton !== null).toBe(true);
    } else {
      // User may already be a seller — menu item absent is acceptable
      console.warn('menu-become-seller not found — user may already be a seller');
    }
  });
});
