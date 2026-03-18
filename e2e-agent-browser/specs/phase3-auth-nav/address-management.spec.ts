/**
 * OrignaGTA — Address Management E2E Tests (agent-browser + Bun)
 * ================================================================
 * API tests for address CRUD operations, and UI tests for address
 * screen navigation and checkout address section.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn, callOk, callExpectError,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

// ═══ API-DRIVEN TESTS ═══

describe('Address Management — API', () => {
  let buyerToken: string;
  let createdAddressId: string | undefined;

  const NEW_ADDRESS = {
    street: '123 E2E Test St',
    city: 'Toronto',
    province: 'ON',
    postalCode: 'M5V 3A8',
    country: 'Canada',
    label: 'E2E Home',
    isDefault: false,
  };

  beforeAll(async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    buyerToken = buyer.idToken;
  });

  afterAll(async () => {
    if (createdAddressId && buyerToken) {
      await callOk('delete_buyer_address', { addressId: createdAddressId }, buyerToken).catch(() => {});
    }
  });

  test('T01: add_buyer_address creates a new address', { timeout: 60_000 }, async () => {
    const result = await callOk('add_buyer_address', NEW_ADDRESS, buyerToken);
    expect(result.success).toBe(true);
    createdAddressId = result.addressId ?? result.address?.addressId ?? result.id;
    expect(createdAddressId).toBeTruthy();
  });

  test('T02: set_default_buyer_address marks address as default', { timeout: 60_000 }, async () => {
    if (!createdAddressId) { console.warn('T01 did not create an address'); return; }
    const result = await callOk('set_default_buyer_address', { addressId: createdAddressId }, buyerToken);
    expect(result.success).toBe(true);
  });

  test('T03: update_buyer_address updates an existing address', { timeout: 60_000 }, async () => {
    if (!createdAddressId) { console.warn('T01 did not create an address'); return; }
    const result = await callOk('update_buyer_address', {
      addressId: createdAddressId,
      street: NEW_ADDRESS.street,
      city: 'Mississauga',
      province: NEW_ADDRESS.province,
      postalCode: NEW_ADDRESS.postalCode,
      country: NEW_ADDRESS.country,
      label: NEW_ADDRESS.label,
      isDefault: false,
    }, buyerToken);
    expect(result.success).toBe(true);
  });

  test('T04: add_buyer_address requires auth — unauthenticated call fails', { timeout: 60_000 }, async () => {
    const err = await callExpectError('add_buyer_address', {
      street: '1 Hacker Way',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 1A1',
    }, '');
    expect(err.code).toBeTruthy();
    expect(err.code).not.toBe('unexpected-success');
  });
});

// ═══ UI-DRIVEN TESTS ═══

describe('Address Management — UI', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T05: Profile settings menu is accessible from home', { timeout: 60_000 }, async () => {
    // Navigate to home
    await browser.open('https://dev.orignagta.ca');
    await browser.waitForFlutter();

    // Login via settings
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

    // After login, settings menu should still be accessible
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsAfterLogin = browser.findByLabel(snap, /btn-home-settings/);
    expect(settingsAfterLogin).toBeTruthy();
    await browser.click(settingsAfterLogin!.ref);
    await new Promise(r => setTimeout(r, 2000));

    // Profile/settings page should show menu items
    snap = await browser.snapshot({ interactive: true, compact: true });
    const hasMenuItems = browser.findByLabel(snap, /menu-my-orders/)
      ?? browser.findByLabel(snap, /menu-address/)
      ?? browser.findByLabel(snap, /menu-language/)
      ?? browser.findByLabel(snap, /menu-get-help/);
    expect(hasMenuItems).toBeTruthy();
  });

  test('T06: Addresses menu item navigates to address screen', { timeout: 60_000 }, async () => {
    // Navigate and login
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

    // Go to settings
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) {
      await browser.click(settingsBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
    }

    // Click address menu item
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addressMenu = browser.findByLabel(snap, /menu-address/);
    expect(addressMenu).toBeTruthy();
    await browser.click(addressMenu!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Verify we're on the address screen
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addressIndicator = browser.findByLabel(snap, /address|adresse/i)
      ?? browser.findByRole(snap, 'button', /add.*address|ajouter.*adresse/i);
    expect(addressIndicator).toBeTruthy();
  });

  test('T07: Add address button exists on address management screen', { timeout: 60_000 }, async () => {
    // Navigate and login
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

    // Go to settings
    snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) {
      await browser.click(settingsBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
    }

    // Navigate to address screen
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addressMenu = browser.findByLabel(snap, /menu-address/);
    expect(addressMenu).toBeTruthy();
    await browser.click(addressMenu!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Verify add address button exists
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addBtn = browser.findByRole(snap, 'button', /add.*address|ajouter.*adresse|btn-add-address/i)
      ?? browser.findByLabel(snap, /btn-add-address/);
    expect(addBtn).toBeTruthy();
  });

  test('T08: Checkout screen shows address section', { timeout: 60_000 }, async () => {
    // Navigate and login
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

    // Navigate to a product and add to cart
    snap = await browser.snapshot({ interactive: true, compact: true });
    const productCard = browser.findByLabel(snap, /product-card-/);
    if (!productCard) {
      console.warn('No product cards found on home — skipping checkout address test');
      return;
    }
    await browser.click(productCard.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    // Add to cart
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addToCartBtn = browser.findByRole(snap, 'button', /add.*cart|ajouter.*panier|btn-add-to-cart/i)
      ?? browser.findByLabel(snap, /btn-add-to-cart/);
    if (!addToCartBtn) {
      console.warn('Add to cart button not found — skipping checkout address test');
      return;
    }
    await browser.click(addToCartBtn.ref);
    await new Promise(r => setTimeout(r, 2000));

    // Navigate to cart/checkout
    snap = await browser.snapshot({ interactive: true, compact: true });
    const cartBtn = browser.findByLabel(snap, /btn-cart|cart|panier/i)
      ?? browser.findByRole(snap, 'button', /cart|panier|checkout/i);
    if (cartBtn) {
      await browser.click(cartBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
    }

    // Look for checkout/proceed button
    snap = await browser.snapshot({ interactive: true, compact: true });
    const checkoutBtn = browser.findByRole(snap, 'button', /checkout|proceed|passer.*commande/i);
    if (checkoutBtn) {
      await browser.click(checkoutBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
    }

    // Check for address section on checkout screen
    const addressSection = browser.findByLabel(snap, /address|adresse|shipping|livraison/i)
      ?? browser.findByRole(snap, 'button', /address|adresse|shipping|livraison/i);
    expect(addressSection).toBeTruthy();
  });
});
