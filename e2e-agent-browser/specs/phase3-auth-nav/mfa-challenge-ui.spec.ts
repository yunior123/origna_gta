/**
 * OrignaGTA — MFA Challenge UI E2E Tests (agent-browser + Bun)
 * =============================================================
 * Tests MFA challenge screen rendering and UI elements.
 * NOTE: Cannot test actual MFA flow — requires real TOTP codes from
 * an enrolled authenticator app. Tests focus on UI rendering only.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, DEFAULT_PASS, WEB_APP_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

describe('MFA Challenge UI', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('MFA challenge screen renders when navigated to', { timeout: 60_000 }, async () => {
    // Navigate to /mfa/challenge — without a valid challengeToken the screen
    // may show an error or empty state, but the route itself should resolve
    // and render the Flutter semantics tree (shield icon, title, input).
    await browser.open(`${TARGET_URL}/mfa/challenge`);
    await browser.waitForFlutter();

    const snap = await browser.snapshot({ interactive: true });

    // The screen should render *something* — either the MFA input form
    // (input-mfa-code, btn-mfa-submit) or a redirect back to login.
    const mfaCodeInput = browser.findByLabel(snap, /input-mfa-code/);
    const submitBtn = browser.findByLabel(snap, /btn-mfa-submit/);
    const recoveryToggle = browser.findByLabel(snap, /btn-use-recovery-code/);
    const loginScreen = browser.findByLabel(snap, /login_email_field|you@example\.com/);

    // Either the MFA challenge screen rendered OR the app redirected to login
    // (expected when no challengeToken is provided).
    const mfaScreenRendered = mfaCodeInput || submitBtn || recoveryToggle;
    const redirectedToLogin = loginScreen != null;

    expect(mfaScreenRendered || redirectedToLogin).toBeTruthy();
  });

  test('Profile has Security menu item', { timeout: 60_000 }, async () => {
    // Login as buyer via browser UI
    await browser.open(`${TARGET_URL}/login`);
    await browser.waitForFlutter();

    let snap = await browser.snapshot({ interactive: true });
    const emailInput = browser.findByLabel(snap, /you@example\.com|login_email_field/);
    if (!emailInput) throw new Error('Email input not found in snapshot');
    await browser.click(emailInput.ref);
    await browser.type(TEST_ACCOUNTS.BUYER_EMAIL);

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

    // Navigate to profile
    snap = await browser.snapshot({ interactive: true });
    const profileBtn = browser.findByLabel(snap, /profile|profil|btn-home-profile|nav-profile/i);
    if (profileBtn) {
      await browser.click(profileBtn.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();
    } else {
      // Try direct navigation
      await browser.open(`${TARGET_URL}/profile`);
      await browser.waitForFlutter();
    }

    snap = await browser.snapshot({ interactive: true });
    const securityMenuItem = browser.findByLabel(snap, /menu-security/);
    expect(securityMenuItem).toBeTruthy();
  });

  test('Security Settings screen renders MFA status card', { timeout: 60_000 }, async () => {
    // Navigate directly to /security (should be authenticated from previous test)
    await browser.open(`${TARGET_URL}/security`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true });

    // Should find either btn-enable-mfa (MFA off) or btn-disable-mfa (MFA on)
    const enableMfaBtn = browser.findByLabel(snap, /btn-enable-mfa/);
    const disableMfaBtn = browser.findByLabel(snap, /btn-disable-mfa/);

    expect(enableMfaBtn || disableMfaBtn).toBeTruthy();
  });
});
