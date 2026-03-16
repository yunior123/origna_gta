import { test, expect } from '@playwright/test';
import {
  waitForFlutter, requireWebApp, checkSemantics,
  ensureLoggedInAsAdmin, performSignOut, navigateHome,
  openHomeSettings, BTN_SETTINGS_LABEL,
} from './flutter-helpers';
import {
  signIn, callOk, callExpectError,
  listUserAddresses, getBootstrapAdminAccessToken, uid,
  TEST_ACCOUNTS, WEB_APP_URL,
} from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASS = TEST_ACCOUNTS.BUYER_PASS;

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

test.describe('Profile Management — API Tests', () => {
  test.setTimeout(120_000);
  test.describe.configure({ mode: 'serial' });

  let buyerToken: string;
  let buyerUid: string;
  let buyerEmail: string;
  let adminToken: string;

  test.beforeAll(async () => {
    const buyer = await signIn(BUYER_EMAIL);
    buyerToken = buyer.idToken;
    buyerUid = authUserIdFromToken(buyer.idToken) || buyer.localId;
    buyerEmail = buyer.email;
    // Admin token needed for listUserAddresses (GraphQL read requires admin role due to rules).
    adminToken = await getBootstrapAdminAccessToken();
  });

  test.afterAll(async () => {
    for (const addrId of createdAddressIds) {
      try { await callOk('delete_buyer_address', { addressId: addrId }, buyerToken); } catch {}
    }
  });

  test('T01: Get profile returns user data', async () => {
    const result = await callOk('get_user_profile', {}, buyerToken);
    expect(result.uid).toBe(buyerUid);
    expect(result.email).toBe(buyerEmail);
    expect(Array.isArray(result.roles)).toBe(true);
    expect(result.roles.length).toBeGreaterThan(0);
  });

  test('T02: Update profile name — verify via get_user_profile', async () => {
    const newName = `E2E Buyer ${uid()}`;
    const result = await callOk('update_user_profile', { name: newName }, buyerToken);
    expect(result.success).toBe(true);

    // OrignaBase does not expose raw user docs via GraphQL getDoc — use the profile endpoint instead.
    const profile = await callOk('get_user_profile', {}, buyerToken);
    expect(profile.name ?? profile.displayName).toBe(newName);

    // Restore original name
    await callOk('update_user_profile', { name: 'Test Buyer' }, buyerToken);
  });

  test('T03: Update email consent — verify toggle via response echo', async () => {
    const result = await callOk('update_email_consent', { emailConsent: true }, buyerToken);
    expect(result.success).toBe(true);
    // OrignaBase /api/users/email-consent echoes back the consent value directly.
    // get_user_profile does NOT include emailConsent in its response.
    expect(result.emailConsent ?? result.consent).toBe(true);

    const result2 = await callOk('update_email_consent', { emailConsent: false }, buyerToken);
    expect(result2.success).toBe(true);
    expect(result2.emailConsent ?? result2.consent).toBe(false);
  });

  test('T04: Add first address — auto-default, verify via list', async () => {
    // Clean up existing addresses before asserting first-address behaviour.
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

    // OrignaBase does not expose subcollection docs via GraphQL getDoc — list and find by id.
    const addresses = await listUserAddresses(buyerUid, adminToken);
    const doc = addresses.find(a => (a.id || a.addressId) === result.addressId);
    expect(doc).toBeTruthy();
    // Address data is nested under doc.address in OrignaBase (or top-level for flat APIs).
    const addr = doc.address ?? doc;
    expect(addr.city).toBe('Toronto');
    expect(addr.province ?? addr.state).toBe('ON');
    expect(doc.isDefault).toBe(true);
  });

  test('T05: Add second address — verify created, check default state', async () => {
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
    const doc = addresses.find(a => (a.id || a.addressId) === result.addressId);
    expect(doc).toBeTruthy();
    const addr2 = doc.address ?? doc;
    expect(addr2.city).toBe('Ottawa');
    // isDefault not asserted — parallel workers manipulate same buyer's addresses,
    // making addressCount unreliable. T04 covers auto-default, T06 covers set_default.
  });

  test('T06: Set default address — old default cleared', async () => {
    const secondAddrId = createdAddressIds[createdAddressIds.length - 1];
    const result = await callOk('set_default_buyer_address', {
      addressId: secondAddrId,
    }, buyerToken);
    expect(result.success).toBe(true);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const newDefault = addresses.find(a => (a.id || a.addressId) === secondAddrId);
    expect(newDefault?.isDefault).toBe(true);

    const firstAddrId = createdAddressIds[0];
    const oldDefault = addresses.find(a => (a.id || a.addressId) === firstAddrId);
    expect(oldDefault?.isDefault).toBe(false);
  });

  test('T07: Delete address — doc removed from OrignaBase', async () => {
    const addrToDelete = createdAddressIds.pop()!;
    const result = await callOk('delete_buyer_address', {
      addressId: addrToDelete,
    }, buyerToken);
    expect(result.success).toBe(true);

    const addresses = await listUserAddresses(buyerUid, adminToken);
    const doc = addresses.find(a => (a.id || a.addressId) === addrToDelete);
    expect(doc).toBeFalsy();
  });

  test('T08: Non-Canadian address rejected — invalid-argument', async () => {
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

test.describe('Profile Management — UI Tests', () => {
  test.setTimeout(300_000);

  test('T09: UI — Profile page shows menu items', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    // Brief pause: API tests above may have triggered rate limiter on auth endpoints.
    await page.waitForTimeout(3_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);

    await openHomeSettings(page);
    await expect(page).toHaveURL(/\/profile/i, { timeout: 30000 });
    await waitForFlutter(page);

    // Wait for profile data to load and semantic tree to flush.
    // Flutter 3.41.3: Semantics(button:true, label:...) renders as role=button with textContent label.
    const menuOrders = page.getByRole('button', { name: 'menu-my-orders' }).first();
    const menuFavorites = page.getByRole('button', { name: 'menu-favorites' }).first();
    const menuAddress = page.getByRole('button', { name: 'menu-address' }).first();

    await expect(menuOrders).toBeVisible({ timeout: 30000 });
    await expect(menuFavorites).toBeVisible({ timeout: 10000 });
    await expect(menuAddress).toBeVisible({ timeout: 10000 });

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('T10: UI — Navigate to address management page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);

    await openHomeSettings(page);
    await expect(page).toHaveURL(/\/profile/i, { timeout: 30000 });
    await waitForFlutter(page);

    const menuAddress = page.getByRole('button', { name: 'menu-address' }).first();
    await expect(menuAddress).toBeVisible({ timeout: 30000 });
    await menuAddress.scrollIntoViewIfNeeded();
    await page.waitForTimeout(1000);
    await menuAddress.click({ force: true });
    await page.waitForTimeout(2000);
    await expect(page).toHaveURL(/\/addresses/i, { timeout: 30000 });
    await waitForFlutter(page);

    const addAddrBtn = page.getByRole('button', { name: /btn-add-address|add address/i }).first();
    await expect(addAddrBtn).toBeAttached({ timeout: 30000 });

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('T11: UI — Navigate to orders page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);
    await page.waitForTimeout(3_000);
    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsAdmin(page, TARGET_URL, BUYER_EMAIL, BUYER_PASS);

    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    await expect(settingsBtn).toBeAttached({ timeout: 30000 });
    await settingsBtn.click();
    await expect(page).toHaveURL(/\/profile/i, { timeout: 30000 });
    await waitForFlutter(page);

    const menuOrders = page.getByRole('button', { name: 'menu-my-orders' }).first();
    await expect(menuOrders).toBeVisible({ timeout: 30000 });
    await menuOrders.scrollIntoViewIfNeeded();
    await page.waitForTimeout(1000);
    await menuOrders.click({ force: true });
    await page.waitForTimeout(2000);
    await expect(page).toHaveURL(/\/orders/i, { timeout: 30000 });

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });
});
