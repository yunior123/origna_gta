/**
 * OrignaGTA — Auth Gates E2E Tests (agent-browser + Bun)
 * ========================================================
 * Tests email verification gate, terms-update gate, suspended-user gate,
 * and shareable product slug links.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  setOrignaBaseUserEmailVerified,
  setOrignaBaseUserSuspended,
  setOrignaBaseUserTermsVersion,
  resolveUiEmail,
  listCollection,
  callExpectError,
  callOk,
} from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS, DEFAULT_PASS, WEB_APP_URL, ORIGNABASE_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

describe('Auth Gates', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('unverified users are blocked by the email verification gate', { timeout: 60_000 }, async () => {
    const email = TEST_ACCOUNTS.BUYER3_EMAIL;
    const uiEmail = resolveUiEmail(email);
    await setOrignaBaseUserEmailVerified(uiEmail, DEFAULT_PASS, false);
    // Wait for OrignaBase to commit the patch before issuing a new JWT
    await new Promise(r => setTimeout(r, 3000));

    try {
      await browser.open(`${TARGET_URL}/login`);
      await browser.waitForFlutter();

      // Fill login form
      let snap = await browser.snapshot({ interactive: true });
      const emailInput = browser.findByLabel(snap, /you@example\.com|login_email_field/);
      if (!emailInput) throw new Error('Email input not found in snapshot');
      await browser.click(emailInput.ref);
      await browser.type(uiEmail);

      snap = await browser.snapshot({ interactive: true });
      const passInput = browser.findByLabel(snap, /login_password_field/);
      if (!passInput) throw new Error('Password input not found in snapshot');
      await browser.click(passInput.ref);
      await browser.type(DEFAULT_PASS);
      await browser.press('Tab');
      await new Promise(r => setTimeout(r, 500));
      await browser.press('Enter');

      // Wait for post-login navigation
      await new Promise(r => setTimeout(r, 5000));
      await browser.waitForFlutter();

      // Check for email verification gate
      snap = await browser.snapshot({ interactive: true });
      const verifyHeadline = browser.findByLabel(snap, /Verify Your Email|verify.*email|v[eé]rifi/i);
      expect(verifyHeadline).toBeTruthy();

      const resendBtn = browser.findByRole(snap, 'button', /resend|renvoyer|Resend Verification/i);
      expect(resendBtn).toBeTruthy();
    } finally {
      await setOrignaBaseUserEmailVerified(uiEmail, DEFAULT_PASS, true);
    }
  });

  test('outdated terms version forces the terms-update gate', { timeout: 60_000 }, async () => {
    const email = TEST_ACCOUNTS.BUYER2_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    await setOrignaBaseUserTermsVersion(email, DEFAULT_PASS, '0.9');

    try {
      await browser.open(`${TARGET_URL}/login`);
      await browser.waitForFlutter();

      // Fill login form
      let snap = await browser.snapshot({ interactive: true });
      const emailInput = browser.findByLabel(snap, /you@example\.com|login_email_field/);
      if (!emailInput) throw new Error('Email input not found in snapshot');
      await browser.click(emailInput.ref);
      await browser.type(resolveUiEmail(email));

      snap = await browser.snapshot({ interactive: true });
      const passInput = browser.findByLabel(snap, /login_password_field/);
      if (!passInput) throw new Error('Password input not found in snapshot');
      await browser.click(passInput.ref);
      await browser.type(DEFAULT_PASS);
      await browser.press('Tab');
      await new Promise(r => setTimeout(r, 500));
      await browser.press('Enter');

      // Wait for post-login navigation
      await new Promise(r => setTimeout(r, 5000));
      await browser.waitForFlutter();

      // Check for terms-update gate
      snap = await browser.snapshot({ interactive: true });
      const termsHeadline = browser.findByLabel(
        snap,
        /Our Terms Have Been Updated|terms.*updated|updated.*terms|conditions.*mise/i,
      );
      expect(termsHeadline).toBeTruthy();

      const scrollHint = browser.findByLabel(
        snap,
        /Scroll to the bottom to enable|Faites d[eé]filer/i,
      );
      expect(scrollHint).toBeTruthy();
    } finally {
      await setOrignaBaseUserTermsVersion(email, DEFAULT_PASS, '1.0');
    }
  });

  test('suspended users are blocked on protected routes', { timeout: 60_000 }, async () => {
    const email = TEST_ACCOUNTS.SELLER1_EMAIL;
    await setOrignaBaseUserEmailVerified(email, DEFAULT_PASS, true);
    await setOrignaBaseUserSuspended(email, DEFAULT_PASS, true);

    try {
      await browser.open(`${TARGET_URL}/login`);
      await browser.waitForFlutter();

      // Fill login form
      let snap = await browser.snapshot({ interactive: true });
      const emailInput = browser.findByLabel(snap, /you@example\.com|login_email_field/);
      if (!emailInput) throw new Error('Email input not found in snapshot');
      await browser.click(emailInput.ref);
      await browser.type(resolveUiEmail(email));

      snap = await browser.snapshot({ interactive: true });
      const passInput = browser.findByLabel(snap, /login_password_field/);
      if (!passInput) throw new Error('Password input not found in snapshot');
      await browser.click(passInput.ref);
      await browser.type(DEFAULT_PASS);
      await browser.press('Tab');
      await new Promise(r => setTimeout(r, 500));
      await browser.press('Enter');

      // Wait for post-login navigation
      await new Promise(r => setTimeout(r, 5000));
      await browser.waitForFlutter();

      // Navigate to settings
      snap = await browser.snapshot({ interactive: true });
      const settingsBtn = browser.findByRole(snap, 'button', /settings|param[eè]tres|btn-home-settings/i);
      if (settingsBtn) {
        await browser.click(settingsBtn.ref);
        await new Promise(r => setTimeout(r, 3000));
        await browser.waitForFlutter();
      }

      // Check for suspended message
      snap = await browser.snapshot({ interactive: true });
      const suspendedMsg = browser.findByLabel(snap, /account.*suspended|suspended.*account|compte.*suspendu/i);
      expect(suspendedMsg).toBeTruthy();

      const contactSupport = browser.findByLabel(snap, /contact.*support|contactez/i);
      expect(contactSupport).toBeTruthy();
    } finally {
      await setOrignaBaseUserSuspended(email, DEFAULT_PASS, false);
    }
  });

  // ═══ AUTH API TESTS ═══

  test('Login with wrong password returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: TEST_ACCOUNTS.BUYER_EMAIL, password: 'WrongPassword999!' }),
    });
    expect(res.ok).toBe(false);
  });

  test('Login with non-existent email returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'nonexistent_user_e2e_' + Date.now() + '@test.origna.ca', password: 'REDACTED_TEST_PASSWORD' }),
    });
    expect(res.ok).toBe(false);
  });

  test('Login with empty email returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: '', password: 'REDACTED_TEST_PASSWORD' }),
    });
    expect(res.ok).toBe(false);
  });

  test('Login with empty password returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: TEST_ACCOUNTS.BUYER_EMAIL, password: '' }),
    });
    expect(res.ok).toBe(false);
  });

  test('Login with SQL injection email returns error (not crash)', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: "'; DROP TABLE users; --", password: 'REDACTED_TEST_PASSWORD' }),
    });
    expect(res.ok).toBe(false);
  });

  test('Register with existing email returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: TEST_ACCOUNTS.BUYER_EMAIL,
        password: 'REDACTED_TEST_PASSWORD',
        displayName: 'Duplicate User',
      }),
    });
    // Should fail — email already exists
    const body = await res.json().catch(() => ({}));
    expect(res.ok === false || (body as any).error).toBeTruthy();
  });

  test('Register with short password returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'short_pass_test_' + Date.now() + '@test.origna.ca',
        password: '123',
        displayName: 'Short Pass',
      }),
    });
    expect(res.ok).toBe(false);
  });

  test('Register with invalid email format returns error', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'not-an-email',
        password: 'REDACTED_TEST_PASSWORD',
        displayName: 'Bad Email',
      }),
    });
    expect(res.ok).toBe(false);
  });

  test('Token from valid login grants access to profile', { timeout: 60_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    expect(auth.idToken).toBeTruthy();
    const result = await callOk('get_user_profile', {}, auth.idToken);
    expect(result).toBeTruthy();
  });

  test('Profile inaccessible with invalid token', { timeout: 60_000 }, async () => {
    const error = await callExpectError('get_user_profile', {}, 'invalid-token-xyz');
    expect(error.code).toMatch(/unauthenticated|permission-denied/i);
  });

  test('shareable product slug links resolve to product detail pages', { timeout: 60_000 }, async () => {
    const products = await listCollection('products');
    const withSlug = products.find(
      (product: any) => typeof product?.slug === 'string' && product.slug.length > 0,
    );
    if (!withSlug) {
      // No products with slug in dev DB — skip
      console.warn('No products with slug in dev DB — skipping slug test');
      return;
    }

    await browser.open(`${TARGET_URL}/p/${encodeURIComponent(withSlug.slug)}`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true });
    const productName = browser.findByLabel(
      snap,
      new RegExp(String(withSlug.name).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'),
    );
    expect(productName).toBeTruthy();
  });
});
