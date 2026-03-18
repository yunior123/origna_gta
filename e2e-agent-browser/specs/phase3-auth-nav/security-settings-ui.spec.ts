/**
 * OrignaGTA — Security Settings UI E2E Tests (agent-browser + Bun)
 * =================================================================
 * Tests the Security Settings screen UI: MFA toggle, login history,
 * known devices sections. Does NOT test actual MFA enable/disable
 * (requires real TOTP codes).
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, DEFAULT_PASS, WEB_APP_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

/** Helper: login via browser UI and wait for navigation. */
async function loginViaBrowser(browser: AgentBrowser, email: string, password: string): Promise<void> {
  await browser.open(`${TARGET_URL}/login`);
  await browser.waitForFlutter();

  let snap = await browser.snapshot({ interactive: true });
  const emailInput = browser.findByLabel(snap, /you@example\.com|login_email_field/);
  if (!emailInput) throw new Error('Email input not found in snapshot');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.snapshot({ interactive: true });
  const passInput = browser.findByLabel(snap, /login_password_field/);
  if (!passInput) throw new Error('Password input not found in snapshot');
  await browser.click(passInput.ref);
  await browser.type(password);
  await browser.press('Tab');
  await new Promise(r => setTimeout(r, 500));
  await browser.press('Enter');

  // Wait for post-login navigation
  await new Promise(r => setTimeout(r, 5000));
  await browser.waitForFlutter();
}

describe('Security Settings UI', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Security Settings screen is accessible from profile', { timeout: 60_000 }, async () => {
    await loginViaBrowser(browser, TEST_ACCOUNTS.BUYER_EMAIL, DEFAULT_PASS);

    // Navigate to profile
    let snap = await browser.snapshot({ interactive: true });
    const profileBtn = browser.findByLabel(snap, /profile|profil|btn-home-profile|nav-profile/i);
    if (profileBtn) {
      await browser.click(profileBtn.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();
    } else {
      await browser.open(`${TARGET_URL}/profile`);
      await browser.waitForFlutter();
    }

    // Find and click the security menu item
    snap = await browser.snapshot({ interactive: true });
    const securityMenuItem = browser.findByLabel(snap, /menu-security/);
    expect(securityMenuItem).toBeTruthy();
    if (!securityMenuItem) throw new Error('menu-security not found');

    await browser.click(securityMenuItem.ref);
    await new Promise(r => setTimeout(r, 3000));
    await browser.waitForFlutter();

    // Verify security screen loaded — should have MFA enable/disable button
    snap = await browser.snapshot({ interactive: true });
    const enableMfa = browser.findByLabel(snap, /btn-enable-mfa/);
    const disableMfa = browser.findByLabel(snap, /btn-disable-mfa/);
    expect(enableMfa || disableMfa).toBeTruthy();
  });

  test('Enable MFA button visible when MFA disabled', { timeout: 60_000 }, async () => {
    // Navigate directly to security screen (should still be authenticated)
    await browser.open(`${TARGET_URL}/security`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true });

    // For a test account that has not enabled MFA, btn-enable-mfa should be present
    const enableMfaBtn = browser.findByLabel(snap, /btn-enable-mfa/);
    const disableMfaBtn = browser.findByLabel(snap, /btn-disable-mfa/);

    // At least one must exist (screen rendered the MFA card)
    expect(enableMfaBtn || disableMfaBtn).toBeTruthy();

    // If MFA is not enabled for the test account, the enable button should appear
    if (!disableMfaBtn) {
      expect(enableMfaBtn).toBeTruthy();
    }
  });

  test('Security screen shows login history section', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET_URL}/security`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true });

    // The login history section uses semantic label 'login-history-list' when
    // there is data, or shows translated 'security.login_history' as a heading.
    const loginHistoryList = browser.findByLabel(snap, /login-history-list/);
    const loginHistoryHeading = browser.findByLabel(snap, /Login History|Historique.*connexion|login.*history/i);
    const noHistoryMsg = browser.findByLabel(snap, /no.*login.*history|aucun.*historique/i);

    // One of these should be present — either the list, the heading, or the empty-state message
    expect(loginHistoryList || loginHistoryHeading || noHistoryMsg).toBeTruthy();
  });

  test('Security screen shows known devices section', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET_URL}/security`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true });

    // The known devices section uses semantic label 'known-devices-list' when
    // there is data, or shows translated 'security.known_devices' heading.
    const knownDevicesList = browser.findByLabel(snap, /known-devices-list/);
    const knownDevicesHeading = browser.findByLabel(snap, /Known Devices|Appareils.*connus|known.*devices/i);
    const noDevicesMsg = browser.findByLabel(snap, /no.*devices|aucun.*appareil/i);

    // One of these should be present
    expect(knownDevicesList || knownDevicesHeading || noDevicesMsg).toBeTruthy();
  });
});
