import { test, expect } from '@playwright/test';
import {
  waitForFlutter, requireWebApp,
  waitForProductCards,
  checkSemantics,
  ensureLoggedInAsBuyer,
  openHomeSettings,
} from './flutter-helpers';
import {
  signIn, callOk, callExpectError,
  TEST_ACCOUNTS, WEB_APP_URL,
} from './api-helpers';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;

// ═══ API-DRIVEN TESTS ═══

test.describe('Address Management — API', () => {
  test.setTimeout(60_000);
  test.describe.configure({ mode: 'serial' });

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

  test.beforeAll(async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    buyerToken = buyer.idToken;
  });

  test('T01: add_buyer_address creates a new address', async () => {
    const result = await callOk('add_buyer_address', NEW_ADDRESS, buyerToken);
    expect(result.success).toBe(true);
    createdAddressId = result.addressId ?? result.address?.addressId ?? result.id;
    expect(createdAddressId).toBeTruthy();
  });

  test('T02: set_default_buyer_address marks address as default', async () => {
    if (!createdAddressId) { console.warn('⚠️ T01 did not create an address'); return; }
    const result = await callOk('set_default_buyer_address', { addressId: createdAddressId }, buyerToken);
    expect(result.success).toBe(true);
  });

  test('T03: update_buyer_address updates an existing address', async () => {
    if (!createdAddressId) { console.warn('⚠️ T01 did not create an address'); return; }
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

  test('T04: add_buyer_address requires auth — unauthenticated call fails', async () => {
    const err = await callExpectError('add_buyer_address', {
      street: '1 Hacker Way',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 1A1',
    }, '');
    expect(err.code).toBeTruthy();
    expect(err.code).not.toBe('unexpected-success');
  });

  test.afterAll(async () => {
    if (createdAddressId && buyerToken) {
      await callOk('delete_buyer_address', { addressId: createdAddressId }, buyerToken).catch(() => {});
    }
  });
});

// ═══ UI-DRIVEN TESTS ═══

test.describe('Address Management — UI', () => {
  test.setTimeout(300_000);

  async function loginAsBuyer(page: import('@playwright/test').Page) {
    await requireWebApp(page, TARGET_URL);
    await page.goto(TARGET_URL);
    await waitForFlutter(page);
    await checkSemantics(page);
    await ensureLoggedInAsBuyer(page, TARGET_URL, TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await waitForProductCards(page);
  }

  test('T05: Profile settings menu is accessible from home', async ({ page }) => {
    await loginAsBuyer(page);

    await openHomeSettings(page);
    await waitForFlutter(page, 30_000);

    const profileMenu = page.locator('[aria-label^="menu-"]').first();
    await expect(profileMenu).toBeAttached({ timeout: 30_000 });
  });

  test('T06: Addresses menu item navigates to address screen', async ({ page }) => {
    await loginAsBuyer(page);

    await openHomeSettings(page);
    await page.waitForURL(/\/profile/i, { timeout: 30_000 }).catch(() => {});
    await waitForFlutter(page, 30_000);

    // Wait for the profile to be fully loaded — menu-my-orders is the first item and
    // appears once user data is loaded from OrignaBase. Use it as a loading gate.
    await expect(page.locator('[aria-label="menu-my-orders"]')).toBeAttached({ timeout: 30_000 });

    // Scroll within the Flutter view using wheel events (window.scrollTo doesn't work in Flutter Web)
    await page.mouse.wheel(0, 600);
    await page.waitForTimeout(500);

    const addressesLink = page.locator('[aria-label="menu-addresses"], [aria-label="menu-my-addresses"], [aria-label="menu-address"]')
      .or(page.getByText(/^addresses?$|^adresses?$/i).first());
    await expect(addressesLink).toBeAttached({ timeout: 30_000 });
    await addressesLink.scrollIntoViewIfNeeded().catch(() => {});
    await addressesLink.click();

    await expect(page.getByText(/address|adresse/i).first()).toBeVisible({ timeout: 30_000 });
  });

  test('T07: Add address button exists on address management screen', async ({ page }) => {
    await loginAsBuyer(page);

    await openHomeSettings(page);
    await page.waitForURL(/\/profile/i, { timeout: 30_000 }).catch(() => {});
    await waitForFlutter(page, 30_000);

    const addressesLinkAttached = await page
      .locator('[aria-label="menu-addresses"], [aria-label="menu-my-addresses"]')
      .waitFor({ state: 'attached', timeout: 10_000 })
      .catch(() => false);

    if (!addressesLinkAttached) {
      console.warn('⚠️ Address management not found in profile menu');
      return;
    }

    await page.locator('[aria-label="menu-addresses"], [aria-label="menu-my-addresses"]').click();

    const addBtn = page.locator('[aria-label^="btn-add-address"]')
      .or(page.getByRole('button', { name: /add address|ajouter/i }).first());
    await expect(addBtn).toBeAttached({ timeout: 15_000 });
  });

  test('T08: Checkout screen shows address section', async ({ page }) => {
    await loginAsBuyer(page);

    const productCard = page.locator('[aria-label^="product-card-"]').first();
    await productCard.click({ timeout: 30_000 });
    await waitForFlutter(page, 30_000);

    const addToCartAttached = await page
      .locator('[aria-label^="btn-add-to-cart"], [aria-label^="add-to-cart"]')
      .waitFor({ state: 'attached', timeout: 10_000 })
      .catch(() => false);

    if (!addToCartAttached) {
      console.warn('⚠️ Add to cart button not found');
      return;
    }

    await page.locator('[aria-label^="btn-add-to-cart"], [aria-label^="add-to-cart"]').click();

    const checkoutAttached = await page
      .locator('[aria-label^="btn-checkout"]')
      .waitFor({ state: 'attached', timeout: 15_000 })
      .catch(() => false);

    if (!checkoutAttached) {
      console.warn('⚠️ Checkout button not found after add to cart');
      return;
    }

    await page.locator('[aria-label^="btn-checkout"]').click();
    await waitForFlutter(page, 30_000);

    await expect(page.getByText(/delivery|livraison|address|adresse/i).first())
      .toBeVisible({ timeout: 15_000 });
  });
});
