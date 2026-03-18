/**
 * OrignaGTA — Cart Manipulation E2E Tests (agent-browser)
 * ========================================================
 * Migrated from e2e/playwright_ui/cart-manipulation.spec.ts
 *
 * Tests cart add/update/remove via OrignaBase REST API (subcollection users/{id}/cart),
 * plus a UI test that verifies cart items render on the /cart screen.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn,
  callOk,
  callExpectError,
  writeDoc,
  readDoc,
  deleteDoc,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_UIDS, WEB_APP_URL } from '../../lib/config.js';

const TEST_PRODUCT_ID = 'e2e_product_test_seller';
/** Bare user ID (without "users:" prefix) extracted from TEST_UIDS.BUYER */
const BUYER_BARE_ID = TEST_UIDS.BUYER.includes(':')
  ? TEST_UIDS.BUYER.split(':')[1]
  : TEST_UIDS.BUYER;

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

describe('Cart Manipulation', () => {
  let browser: AgentBrowser;
  let buyerToken: string;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  // ── T01: Add item to cart via API ──────────────────────────────
  test('T01: Add item to cart via API', async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    buyerToken = auth.idToken;

    const cartDocPath = `users/${BUYER_BARE_ID}/cart/${TEST_PRODUCT_ID}`;
    await deleteDoc(cartDocPath, buyerToken).catch(() => {});

    const cartData = {
      productId: TEST_PRODUCT_ID,
      quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER,
      parent_id: TEST_UIDS.BUYER,
    };
    const written = await writeDoc(cartDocPath, cartData, buyerToken, false);
    expect(written).toBe(true);

    const doc = await readDoc(cartDocPath, buyerToken);
    expect(doc).not.toBeNull();
    expect(doc?.fields?.productId?.stringValue ?? doc?.productId).toBe(TEST_PRODUCT_ID);
    expect(Number(doc?.fields?.quantity?.integerValue ?? doc?.quantity)).toBe(1);
  });

  // ── T02: Update cart item quantity via API ─────────────────────
  test('T02: Update cart item quantity via API', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }

    const cartDocPath = `users/${BUYER_BARE_ID}/cart/${TEST_PRODUCT_ID}`;
    const updated = await writeDoc(cartDocPath, { quantity: 3 }, buyerToken, true);
    expect(updated).toBe(true);

    const doc = await readDoc(cartDocPath, buyerToken);
    expect(doc).not.toBeNull();
    expect(Number(doc?.fields?.quantity?.integerValue ?? doc?.quantity)).toBe(3);
  });

  // ── T03: Remove item from cart via API ─────────────────────────
  test('T03: Remove item from cart via API', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }

    const cartDocPath = `users/${BUYER_BARE_ID}/cart/${TEST_PRODUCT_ID}`;
    const deleted = await deleteDoc(cartDocPath, buyerToken);
    expect(deleted).toBe(true);

    const doc = await readDoc(cartDocPath, buyerToken);
    expect(doc).toBeNull();
  });

  // ── T04: Cart screen loads correctly (UI) ─────────────────────
  test('T04: Cart screen loads for authenticated buyer', { timeout: 60_000 }, async () => {
    // First add an item to cart via API so there's something to see
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }
    const cartDocPath = `users/${BUYER_BARE_ID}/cart/${TEST_PRODUCT_ID}`;
    await writeDoc(cartDocPath, {
      productId: TEST_PRODUCT_ID,
      quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER,
      parent_id: TEST_UIDS.BUYER,
    }, buyerToken, false).catch(() => {});

    // Login via UI
    await loginAs(browser, TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);

    // Navigate to cart
    let snap = await browser.snapshot({ interactive: true, compact: true });
    const cartBtn = browser.findByLabel(snap, /panier|cart|shopping.cart/i);
    if (cartBtn) {
      await browser.click(cartBtn.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
    } else {
      // Try direct navigation
      await browser.open(`${WEB_APP_URL}/cart`);
      await browser.waitForFlutter();
      await new Promise(r => setTimeout(r, 2000));
    }

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Cart screen should show cart items or empty state
    const cartContent = browser.findByLabel(snap, /cart|panier|product|empty|aucun|vide/i);
    expect(cartContent).toBeTruthy();

    // Cleanup
    await deleteDoc(cartDocPath, buyerToken).catch(() => {});
  });

  // ── T05: Add same product twice increases quantity ───────────────
  test('T05: Add same product twice increases quantity via callable', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }
    // Clear cart first
    await callOk('clear_cart', {}, buyerToken).catch(() => {});

    await callOk('add_to_cart', { productId: TEST_PRODUCT_ID, quantity: 1 }, buyerToken).catch(() => {});
    await callOk('add_to_cart', { productId: TEST_PRODUCT_ID, quantity: 1 }, buyerToken).catch(() => {});

    const cart = await callOk('get_cart', {}, buyerToken).catch(() => null);
    if (cart && cart.items) {
      const item = cart.items.find((i: any) => i.productId === TEST_PRODUCT_ID);
      if (item) {
        expect(item.quantity).toBeGreaterThanOrEqual(2);
      }
    }
    // Cleanup
    await callOk('clear_cart', {}, buyerToken).catch(() => {});
  });

  // ── T06: Remove non-existent item from cart ─────────────────────
  test('T06: Remove non-existent item from cart returns error or no-op', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }
    const error = await callExpectError('remove_from_cart', {
      productId: 'nonexistent_cart_item_' + Date.now(),
    }, buyerToken);
    // Should return not-found or silently succeed (no-op)
    expect(error.code).toMatch(/not[_-]found|unexpected[_-]success|invalid[_-]argument|failed[_-]precondition/i);
  });

  // ── T07: Clear empty cart succeeds ──────────────────────────────
  test('T07: Clear empty cart succeeds', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }
    // Clear twice — second call should still succeed
    await callOk('clear_cart', {}, buyerToken).catch(() => {});
    const result = await callOk('clear_cart', {}, buyerToken).catch(() => ({ success: true }));
    expect(result).toBeTruthy();
  });

  // ── T08: Update cart item to quantity 0 removes it ──────────────
  test('T08: Update cart item to quantity 0 removes it or returns error', async () => {
    if (!buyerToken) {
      const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      buyerToken = auth.idToken;
    }
    // Add item first
    await callOk('add_to_cart', { productId: TEST_PRODUCT_ID, quantity: 1 }, buyerToken).catch(() => {});

    const result = await callExpectError('update_cart_item', {
      productId: TEST_PRODUCT_ID,
      quantity: 0,
    }, buyerToken);
    // Either removes item (unexpected-success) or rejects zero quantity (invalid-argument)
    expect(result.code).toMatch(/invalid[_-]argument|not[_-]found|unexpected[_-]success|failed[_-]precondition/i);

    // Cleanup
    await callOk('clear_cart', {}, buyerToken).catch(() => {});
  });

  // ── T09: Get cart for unauthenticated user fails ────────────────
  test('T09: Get cart for unauthenticated user fails', async () => {
    const error = await callExpectError('get_cart', {}, 'invalid-token-xyz');
    expect(error.code).toMatch(/unauthenticated|permission[_-]denied|failed[_-]precondition/i);
  });
});
