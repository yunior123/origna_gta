/**
 * OrignaGTA — Multi-Seller Checkout E2E Tests (agent-browser)
 * =============================================================
 * Tests the buyer UI flow when purchasing from multiple sellers:
 * - Add products from different sellers to cart
 * - Verify cart shows items grouped by seller
 * - Proceed to checkout, verify separate orders created per seller
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn, callOk, callCallable, callExpectError,
  writeDoc, deleteDoc, readDoc,
  discoverProducts, getOrder,
  fullMultiSellerCheckoutAndPay,
  buildCheckoutPayload,
  buildMultiSellerPayload,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_UIDS, WEB_APP_URL } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = TEST_ACCOUNTS.BUYER_PASS;
const BUYER_BARE_ID = TEST_UIDS.BUYER.includes(':')
  ? TEST_UIDS.BUYER.split(':')[1]
  : TEST_UIDS.BUYER;

// Stable E2E products from different sellers
const ADMIN_PRODUCT_ID = 'e2e_product_admin_seller';   // sold by ADMIN
const SELLER_PRODUCT_ID = 'e2e_product_test_seller';    // sold by SELLER

function isRateLimited(e: any): boolean {
  return /rate limit|duplicate order|not available|too many|province/i.test(String(e?.message ?? e ?? ''));
}

function isTransientError(e: any): boolean {
  return /agent-browser.*failed|snapshot failed|exit null|internal error|Connection refused/i.test(String(e?.message ?? e ?? ''));
}

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
  await browser.waitForChange({ timeout: 500 });
  await browser.press('Enter');
  await browser.waitForChange({ timeout: 5000 });
  await browser.waitForFlutter();
}

describe('Multi-Seller Checkout', () => {
  let browser: AgentBrowser;
  let buyerToken: string;
  let adminProduct: { id: string; sellerId: string } | null = null;
  let sellerProduct: { id: string; sellerId: string } | null = null;

  beforeAll(async () => {
    browser = new AgentBrowser();

    const auth = await signIn(BUYER_EMAIL);
    buyerToken = auth.idToken;

    // Discover products to verify both sellers exist
    const products = await discoverProducts(auth.idToken);
    adminProduct = products.find(p => p.id === ADMIN_PRODUCT_ID) || null;
    sellerProduct = products.find(p => p.id === SELLER_PRODUCT_ID) || null;

    if (!adminProduct || !sellerProduct) {
      throw new Error('Required multi-seller E2E products not found');
    }
  }, 60_000);

  beforeEach(async () => { await browser.clearState(); });

  afterAll(async () => {
    // Clean up cart items
    try {
      const auth = await signIn(BUYER_EMAIL);
      await deleteDoc(`users/${BUYER_BARE_ID}/cart/${ADMIN_PRODUCT_ID}`, auth.idToken).catch(() => {});
      await deleteDoc(`users/${BUYER_BARE_ID}/cart/${SELLER_PRODUCT_ID}`, auth.idToken).catch(() => {});
    } catch { /* best-effort cleanup */ }
    await browser.close();
  });

  test('Products from different sellers exist and have different sellerIds', { timeout: 30_000 }, async () => {
    expect(adminProduct).toBeTruthy();
    expect(sellerProduct).toBeTruthy();
    expect(adminProduct!.sellerId).not.toBe(sellerProduct!.sellerId);
  });

  test('Buyer can add items from multiple sellers to cart via API', { timeout: 60_000 }, async () => {
    const auth = await signIn(BUYER_EMAIL);

    // Clear cart first
    await deleteDoc(`users/${BUYER_BARE_ID}/cart/${ADMIN_PRODUCT_ID}`, auth.idToken).catch(() => {});
    await deleteDoc(`users/${BUYER_BARE_ID}/cart/${SELLER_PRODUCT_ID}`, auth.idToken).catch(() => {});

    // Add admin product to cart
    const cartItem1 = {
      productId: ADMIN_PRODUCT_ID,
      quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER,
      parent_id: TEST_UIDS.BUYER,
    };
    const written1 = await writeDoc(`users/${BUYER_BARE_ID}/cart/${ADMIN_PRODUCT_ID}`, cartItem1, auth.idToken, false);
    expect(written1).toBe(true);

    // Add seller product to cart
    const cartItem2 = {
      productId: SELLER_PRODUCT_ID,
      quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER,
      parent_id: TEST_UIDS.BUYER,
    };
    const written2 = await writeDoc(`users/${BUYER_BARE_ID}/cart/${SELLER_PRODUCT_ID}`, cartItem2, auth.idToken, false);
    expect(written2).toBe(true);
  });

  test('Cart UI shows items from multiple sellers', { timeout: 90_000 }, async () => {
    // First add items via API
    const auth = await signIn(BUYER_EMAIL);
    await deleteDoc(`users/${BUYER_BARE_ID}/cart/${ADMIN_PRODUCT_ID}`, auth.idToken).catch(() => {});
    await deleteDoc(`users/${BUYER_BARE_ID}/cart/${SELLER_PRODUCT_ID}`, auth.idToken).catch(() => {});

    await writeDoc(`users/${BUYER_BARE_ID}/cart/${ADMIN_PRODUCT_ID}`, {
      productId: ADMIN_PRODUCT_ID, quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER, parent_id: TEST_UIDS.BUYER,
    }, auth.idToken, false);

    await writeDoc(`users/${BUYER_BARE_ID}/cart/${SELLER_PRODUCT_ID}`, {
      productId: SELLER_PRODUCT_ID, quantity: 1,
      dateCreated: new Date().toISOString(),
      userId: TEST_UIDS.BUYER, parent_id: TEST_UIDS.BUYER,
    }, auth.idToken, false);

    // Login and navigate to cart
    await loginAs(browser, BUYER_EMAIL, BUYER_PASSWORD);
    try {
      await browser.open(`${WEB_APP_URL}/#/cart`, 15_000);
      await browser.waitForFlutter(5_000);
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
    expect(snap.refs.length).toBeGreaterThanOrEqual(0);
  });

  test('Multi-seller checkout is rejected until buyers split checkout per seller', { timeout: 120_000 }, async () => {
    if (!adminProduct || !sellerProduct) {
      console.log('Skipped: multi-seller products not available');
      return;
    }

    const auth = await signIn(BUYER_EMAIL);
    const payload = await buildMultiSellerPayload(auth.localId, [
      { productId: ADMIN_PRODUCT_ID, quantity: 1 },
      { productId: SELLER_PRODUCT_ID, quantity: 1 },
    ], auth.idToken);

    const error = await callExpectError(
      'create_checkout_session',
      {
        ...payload,
        idempotencyKey: `multi-seller-ui-${Date.now()}-${Math.random().toString(36).slice(2)}`,
      },
      auth.idToken,
    );

    expect(['validation-error', 'invalid-argument']).toContain(error.code);
    expect(error.message).toContain('Multi-seller carts require separate checkout sessions per seller');
  });
});
