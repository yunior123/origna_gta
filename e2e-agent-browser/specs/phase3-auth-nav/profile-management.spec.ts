/**
 * OrignaGTA — Profile Management E2E Tests (agent-browser + Bun)
 * ================================================================
 * API tests for profile CRUD + address management, and UI tests for
 * profile page navigation.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn, callOk, callExpectError,
  listUserAddresses, getBootstrapAdminAccessToken, uid,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

const createdAddressIds: string[] = [];

function authUserIdFromToken(token: string): string {
  try {
    const [, payload] = token.split('.');
    if (!payload) return '';
    const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    return decoded.user_id || decoded.sub || decoded.uid || '';
  } catch {
    return '';
  }
}

// ═══ API-DRIVEN TESTS ═══

describe('Profile Management — API Tests', () => {
  let buyerToken: string;
  let buyerUid: string;
  let buyerEmail: string;
  let adminToken: string;

  beforeAll(async () => {
    const buyer = await signIn(BUYER_EMAIL);
    buyerToken = buyer.idToken;
    buyerUid = authUserIdFromToken(buyer.idToken) || buyer.localId;
    buyerEmail = buyer.email;
    adminToken = await getBootstrapAdminAccessToken();
  });

  afterAll(async () => {
    for (const addrId of createdAddressIds) {
      try { await callOk('delete_buyer_address', { addressId: addrId }, buyerToken); } catch {}
    }
  });

  test('T01: Get profile returns user data', { timeout: 120_000 }, async () => {
    const result = await callOk('get_user_profile', {}, buyerToken);
    expect(result.uid).toBe(buyerUid);
    expect(result.email).toBe(buyerEmail);
    expect(Array.isArray(result.roles)).toBe(true);
    expect(result.roles.length).toBeGreaterThan(0);
  });

  test('T02: Update profile name — verify via get_user_profile', { timeout: 120_000 }, async () => {
    const newName = `E2E Buyer ${uid()}`;
    const result = await callOk('update_user_profile', { name: newName }, buyerToken);
    expect(result.success).toBe(true);

    const profile = await callOk('get_user_profile', {}, buyerToken);
    expect(profile.name ?? profile.displayName).toBe(newName);

    // Restore original name
    await callOk('update_user_profile', { name: 'Test Buyer' }, buyerToken);
  });

  test('T03: Update email consent — verify toggle via response echo', { timeout: 120_000 }, async () => {
    const result = await callOk('update_email_consent', { emailConsent: true }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.emailConsent ?? result.consent).toBe(true);

    const result2 = await callOk('update_email_consent', { emailConsent: false }, buyerToken);
    expect(result2.success).toBe(true);
    expect(result2.emailConsent ?? result2.consent).toBe(false);
  });

  test('T04: Add first address — auto-default, verify via list', { timeout: 120_000 }, async () => {
    // Clean up existing addresses
    const existing = await listUserAddresses(buyerUid, adminToken);
    for (const doc of existing) {
      const addrId = doc.id || doc.addressId;
      if (addrId) {
        await callOk('delete_buyer_address', { addressId: addrId }, buyerToken).catch(() => {});
      }
    }

    const result = await callOk('add_buyer_address', {
      street: '100 Test Street',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
      phoneNumber: '+14165550001',
      label: 'Home',
      isDefault: true,
    }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.addressId).toBeTruthy();
    createdAddressIds.push(result.addressId);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const doc = addresses.find((a: any) => (a.id || a.addressId) === result.addressId);
    expect(doc).toBeTruthy();
    const addr = doc.address ?? doc;
    expect(addr.city).toBe('Toronto');
    expect(addr.province ?? addr.state).toBe('ON');
    expect(doc.isDefault).toBe(true);
  });

  test('T05: Add second address — verify created, check default state', { timeout: 120_000 }, async () => {
    const result = await callOk('add_buyer_address', {
      street: '200 Queen Street',
      city: 'Ottawa',
      state: 'ON',
      postalCode: 'K1A 0A6',
      country: 'Canada',
      phoneNumber: '+16135550002',
      label: 'Work',
    }, buyerToken);
    expect(result.success).toBe(true);
    createdAddressIds.push(result.addressId);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const doc = addresses.find((a: any) => (a.id || a.addressId) === result.addressId);
    expect(doc).toBeTruthy();
    const addr2 = doc.address ?? doc;
    expect(addr2.city).toBe('Ottawa');
  });

  test('T06: Set default address — old default cleared', { timeout: 120_000 }, async () => {
    const secondAddrId = createdAddressIds[createdAddressIds.length - 1];
    const result = await callOk('set_default_buyer_address', {
      addressId: secondAddrId,
    }, buyerToken);
    expect(result.success).toBe(true);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const newDefault = addresses.find((a: any) => (a.id || a.addressId) === secondAddrId);
    expect(newDefault?.isDefault).toBe(true);

    const firstAddrId = createdAddressIds[0];
    const oldDefault = addresses.find((a: any) => (a.id || a.addressId) === firstAddrId);
    expect(oldDefault?.isDefault).toBe(false);
  });

  test('T07: Delete address — doc removed from OrignaBase', { timeout: 120_000 }, async () => {
    const addrToDelete = createdAddressIds.pop()!;
    const result = await callOk('delete_buyer_address', {
      addressId: addrToDelete,
    }, buyerToken);
    expect(result.success).toBe(true);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const doc = addresses.find((a: any) => (a.id || a.addressId) === addrToDelete);
    expect(doc).toBeFalsy();
  });

  test('T08: Non-Canadian address rejected — invalid-argument', { timeout: 120_000 }, async () => {
    const error = await callExpectError('add_buyer_address', {
      street: '1 Main St',
      city: 'New York',
      state: 'NY',
      postalCode: '10001',
      country: 'United States',
      phoneNumber: '+12125550003',
      label: 'Other',
    }, buyerToken);
    expect(error.code).toBe('invalid-argument');
  });
});

// ═══ UI-DRIVEN TESTS ═══

describe('Profile Management — UI Tests', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T09: UI — Profile page shows menu items', { timeout: 60_000 }, async () => {
    // Navigate to home and login
    await browser.open('https://dev.orignagta.ca');
    await browser.waitForFlutter();

    let snap = await browser.snapshot({ interactive: true, compact: true });
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

    // Navigate to settings/profile page
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsAfterLogin = browser.findByLabel(snap, /btn-home-settings/);
    expect(settingsAfterLogin).toBeTruthy();
    await browser.click(settingsAfterLogin!.ref);
    await new Promise(r => setTimeout(r, 2000));

    // Verify key menu items exist
    snap = await browser.snapshot({ interactive: true, compact: true });
    const ordersMenu = browser.findByLabel(snap, /menu-my-orders/);
    const addressMenu = browser.findByLabel(snap, /menu-address/);
    const languageMenu = browser.findByLabel(snap, /menu-language/);
    const helpMenu = browser.findByLabel(snap, /menu-get-help/);
    const signOutBtn = browser.findByLabel(snap, /btn-sign-out/);

    // At least 3 of these standard menu items should be present
    const foundCount = [ordersMenu, addressMenu, languageMenu, helpMenu, signOutBtn]
      .filter(item => item !== null).length;
    expect(foundCount).toBeGreaterThanOrEqual(3);
  });

  test('T10: UI — Navigate to address management page', { timeout: 60_000 }, async () => {
    // Navigate and login
    await browser.open('https://dev.orignagta.ca');
    await browser.waitForFlutter();

    let snap = await browser.snapshot({ interactive: true, compact: true });
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

    // Go to settings
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) {
      await browser.click(settingsBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
    }

    // Click address menu
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addressMenu = browser.findByLabel(snap, /menu-address/);
    expect(addressMenu).toBeTruthy();
    await browser.click(addressMenu!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Verify address management page loaded
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addressIndicator = browser.findByLabel(snap, /address|adresse/i)
      ?? browser.findByRole(snap, 'button', /add.*address|ajouter.*adresse|btn-add-address/i)
      ?? browser.findByLabel(snap, /btn-add-address/);
    expect(addressIndicator).toBeTruthy();
  });

  test('T11: UI — Navigate to orders page', { timeout: 60_000 }, async () => {
    // Navigate and login
    await browser.open('https://dev.orignagta.ca');
    await browser.waitForFlutter();

    let snap = await browser.snapshot({ interactive: true, compact: true });
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

    // Go to settings
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) {
      await browser.click(settingsBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
    }

    // Click orders menu
    snap = await browser.snapshot({ interactive: true, compact: true });
    const ordersMenu = browser.findByLabel(snap, /menu-my-orders/);
    expect(ordersMenu).toBeTruthy();
    await browser.click(ordersMenu!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Verify orders page loaded — should show order list or empty state
    snap = await browser.snapshot({ interactive: true, compact: true });
    const ordersIndicator = browser.findByLabel(snap, /order|commande/i)
      ?? browser.findByLabel(snap, /no.*orders|aucune.*commande|empty/i)
      ?? browser.findByRole(snap, 'button', /order|commande/i);
    expect(ordersIndicator).toBeTruthy();
  });
});
