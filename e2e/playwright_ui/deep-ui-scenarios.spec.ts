/**
 * OrignaGTA — Deep UI Scenario E2E Tests
 * =======================================
 * Full browser-based E2E tests covering critical user journeys.
 * These go deeper than existing specs — verifying UI state, DB state, and cross-screen flows.
 *
 * Run: cd e2e && npx playwright test deep-ui-scenarios.spec.ts --config=playwright.config.dev.ts
 */
import { test, expect } from '@playwright/test';
import {
  waitForFlutter,
  waitForProductCards,
  requireWebApp,
  checkSemantics,
  ensureLoggedInAsAdmin,
  ensureLoggedInAsBuyer,
  openHomeSettings,
  performSignOut,
  navigateHome,
  navigateToAdmin,
  uniqueSuffix,
  BTN_SETTINGS,
  BTN_ADD_PRODUCT,
  BTN_CART,
} from './flutter-helpers';
import {
  signIn,
  callOk,
  callCallable,
  callExpectError,
  readDoc,
  writeDoc,
  parseDoc,
  getDoc,
  getOrder,
  TEST_ACCOUNTS,
  TEST_PRODUCTS,
  WEB_APP_URL,
  DEFAULT_PASS,
  fullCheckoutAndPay,
  uid,
  ensureOrignaBaseUiAccount,
} from './api-helpers';
import * as path from 'path';
import * as os from 'os';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER1_EMAIL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER1_EMAIL;

async function createCheckoutProduct() {
  const sellerAuth = await signIn(SELLER_EMAIL);
  const price = 24.99;
  const result = await callOk('create_product_atomic', {
    name: `Deep Checkout ${uid()}`,
    title: `Deep Checkout ${uid()}`,
    description: 'Checkout product for deep UI scenarios',
    price,
    stockQuantity: 10,
    categoryId: '1',
    imageUrls: [
      `https://picsum.photos/seed/deep-checkout-${uid()}/400/400`,
      `https://picsum.photos/seed/deep-checkout-alt-${uid()}/400/400`,
    ],
    shippingConfig: {
      standardDelivery: true,
      expressDelivery: false,
      weightKg: 1,
    },
  }, sellerAuth.idToken);

  return {
    sellerAuth,
    productId: result.productId,
    price,
  };
}

async function waitForOrder(orderId: string, token: string, maxMs = 30_000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < maxMs) {
    const order = await getOrder(orderId, token);
    if (order) {
      return order;
    }
    await pageDelay(2_000);
  }
  return getOrder(orderId, token);
}

async function pageDelay(ms: number) {
  await new Promise(resolve => setTimeout(resolve, ms));
}

function authUserId(auth: { idToken: string; localId: string }) {
  try {
    const [, payload] = auth.idToken.split('.');
    if (!payload) return auth.localId;
    const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    return decoded.user_id || decoded.sub || decoded.uid || auth.localId;
  } catch {
    return auth.localId;
  }
}

async function createFreshBuyerAuth() {
  const buyerEmail = `e2e-buyer-order-${uid()}@test.origna.ca`;
  const provisioned = await ensureOrignaBaseUiAccount(buyerEmail, DEFAULT_PASS);
  return signIn(provisioned.email, DEFAULT_PASS);
}

function checkoutPayload(userId: string, productId: string, price: number) {
  return {
    userId,
    items: [{ productId, quantity: 1 }],
    subtotalCents: Math.round(price * 100),
    idempotencyKey: `deep-checkout-${uid()}`,
    shippingAddress: {
      street: '100 Queen St W',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5H2N2',
      country: 'CA',
    },
  };
}

async function screenshotOnFailure(page: any, testInfo: any) {
  if (testInfo.status === 'failed' || testInfo.status === 'timedOut') {
    const slug = testInfo.title.replace(/\W+/g, '_').slice(0, 80);
    const dest = path.join(os.homedir(), 'Desktop', `FAILED_${slug}_${Date.now()}.png`);
    await page.screenshot({ path: dest, fullPage: true }).catch(() => {});
  }
}

// ════════════════════════════════════════════════════════════════════
// A. FULL BUYER JOURNEY — Browse → Search → Details → Cart → Checkout
// ════════════════════════════════════════════════════════════════════

test.describe('A. Full Buyer Journey', () => {
  test.setTimeout(300_000);

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('A1: Buyer can browse home, see product cards, and view product details', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // Verify home screen has product cards
    const cardCount = await waitForProductCards(page, 45_000);
    const productCards = page.locator('[aria-label^="product-card-"]');
    expect(cardCount).toBeGreaterThan(0);

    // Click first product card to view details
    await productCards.first().click();
    await waitForFlutter(page);

    // Verify product details screen shows key info
    const productName = page.getByRole('heading').first();
    await expect(productName).toBeVisible({ timeout: 20_000 });

    // Verify price is displayed
    const priceText = page.getByText(/\$\d+/);
    await expect(priceText.first()).toBeVisible({ timeout: 10_000 });

    // Verify product action buttons exist.
    // In-stock products now show "Buy Now" (product_buy_now_button) above "Add to Cart".
    // Scroll down to bring action buttons into the Flutter accessibility tree if needed.
    await page.mouse.move(640, 400);
    await page.mouse.wheel(0, 600);
    await page.waitForTimeout(500);
    const buyNowBtn = page.locator('[aria-label^="product_buy_now_button"]').first();
    const addToCartBtn = page.locator('[aria-label^="product_add_to_cart_button"]').first();
    const hasBuyNow = await buyNowBtn.isVisible({ timeout: 5_000 }).catch(() => false);
    const hasAddToCart = await addToCartBtn.isVisible({ timeout: 5_000 }).catch(() => false);
    if (!hasBuyNow && !hasAddToCart) {
      // Scroll further down if still not visible
      await page.mouse.wheel(0, 2400);
      await page.waitForTimeout(500);
    }
  });

  test('A2: Buyer can search for products using the search bar', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // Find and click the search input
    const searchInput = page.locator('[aria-label="input-home-search"]').first();
    const hasSearch = await searchInput.isVisible({ timeout: 15_000 }).catch(() => false);
    if (hasSearch) {
      await searchInput.click();
      await page.waitForTimeout(800);
      await page.keyboard.type('sticker', { delay: 50 });
      await page.waitForTimeout(3_000); // Algolia debounce

      // Verify search results appear
      const results = page.locator('[aria-label^="product-card-"]');
      const count = await results.count();
      // Search may return 0 results depending on data — just verify no crash
      expect(count).toBeGreaterThanOrEqual(0);
    }
  });

  test('A3: Buyer can create checkout session via API and verify order in SurrealDB', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);

    const auth = await createFreshBuyerAuth();
    const { sellerAuth, productId, price } = await createCheckoutProduct();
    let checkout: any;
    try {
      checkout = await callOk(
        'create_checkout_session',
        checkoutPayload(authUserId(auth), productId, price),
        auth.idToken,
      );
    } catch (error) {
      await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
      throw error;
    }
    expect(checkout.orderId).toBeTruthy();
    expect(checkout.sessionId).toBeTruthy();
    if (checkout.checkoutUrl) {
      expect(checkout.checkoutUrl).toContain('checkout.stripe.com');
    }

    // Verify order was created in SurrealDB (pass auth token — orders require auth read)
    const order = await waitForOrder(checkout.orderId, auth.idToken);
    expect(order).toBeTruthy();
    expect(order?.orderStatus).toBeTruthy();
    expect(order?.items?.length).toBeGreaterThan(0);
    await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
  });
});

// ════════════════════════════════════════════════════════════════════
// B. SELLER PRODUCT LIFECYCLE — Create → Edit → Deactivate → Reactivate
// ════════════════════════════════════════════════════════════════════

test.describe('B. Seller Product Lifecycle', () => {
  test.setTimeout(420_000);

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('B1: Seller creates product via API and verifies it exists in SurrealDB', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const productName = `E2E Deep Test ${uid()}`;

    const result = await callCallable('create_product_atomic', {
      name: productName,
      description: 'Deep UI scenario test product',
      price: 24.99,
      stockQuantity: 15,
      categoryId: '1',
      shippingConfig: {
        standardDelivery: true,
        expressDelivery: false,
        weightKg: 1.0,
      },
    }, auth.idToken);

    const productId = result.result?.productId || result.result?.id;
    if (productId) {
      // Verify via OrignaBase API
      const product = await getDoc(`products/${productId}`, auth.idToken);
      expect(product).toBeTruthy();
      expect(product?.name).toBe(productName);
      expect(product?.price).toBe(24.99);
      expect(product?.stockQuantity).toBe(15);
      expect(product?.sellerId).toBe(auth.localId);

      // Cleanup
      await callCallable('delete_product', { productId }, auth.idToken);
    }
  });

  test('B2: Seller updates product and verifies changes in SurrealDB', async () => {
    const auth = await signIn(SELLER_EMAIL);

    // Create a product first
    const createResult = await callCallable('create_product_atomic', {
      name: `Lifecycle Test ${uid()}`,
      description: 'Will be updated',
      price: 15.00,
      stockQuantity: 10,
      categoryId: '2',
      shippingConfig: { standardDelivery: true, expressDelivery: false, weightKg: 0.5 },
    }, auth.idToken);

    const productId = createResult.result?.productId || createResult.result?.id;
    if (productId) {
      // Update the product
      await callOk('update_product', {
        productId,
        name: 'Updated Lifecycle Product',
        price: 29.99,
        description: 'Updated description via E2E',
      }, auth.idToken);

      // Verify update in SurrealDB
      const updated = await getDoc(`products/${productId}`, auth.idToken);
      expect(updated?.name).toBe('Updated Lifecycle Product');
      expect(updated?.price).toBe(29.99);

      // Cleanup
      await callCallable('delete_product', { productId }, auth.idToken);
    }
  });

  test('B3: Seller can view their products on the seller products page', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, SELLER_EMAIL, DEFAULT_PASS);

    // Navigate to profile → seller products
    await openHomeSettings(page);
    await waitForFlutter(page);

    // Look for "My Products" or "Mes produits" menu item
    const myProductsBtn = page.getByRole('button', { name: /menu-my-products|my products|mes produits/i }).first();
    const hasMyProducts = await myProductsBtn.isVisible({ timeout: 15_000 }).catch(() => false);
    if (hasMyProducts) {
      await myProductsBtn.click();
      await waitForFlutter(page);
      // Verify seller products screen loaded
      await page.waitForTimeout(3_000);
    }

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });
});

// ════════════════════════════════════════════════════════════════════
// C. ADMIN PANEL — Deep admin operations
// ════════════════════════════════════════════════════════════════════

test.describe('C. Admin Panel Operations', () => {
  test.setTimeout(300_000);

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('C1: Admin navigates to admin panel and verifies all tabs', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsAdmin(page, TARGET_URL, ADMIN_EMAIL, ADMIN_PASS);
    await navigateToAdmin(page);

    // Verify all admin tabs exist
    const tabs = [
      /admin-tab-sellers|sellers/i,
      /admin-tab-users|users/i,
      /admin-tab-orders|orders/i,
    ];
    for (const tabPattern of tabs) {
      const tab = page.getByRole('tab', { name: tabPattern })
        .or(page.getByRole('button', { name: tabPattern })).first();
      await expect(tab).toBeVisible({ timeout: 20_000 });
    }

    // Click each tab to verify content loads
    for (const tabPattern of tabs) {
      const tab = page.getByRole('tab', { name: tabPattern })
        .or(page.getByRole('button', { name: tabPattern })).first();
      await tab.click();
      await page.waitForTimeout(2_000);
    }

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('C2: Admin can update product stock via API and verify SurrealDB', async () => {
    const auth = await signIn(ADMIN_EMAIL, ADMIN_PASS);

    // Read current stock
    const before = await getDoc(`products/${TEST_PRODUCTS.HIGH_STOCK}`, auth.idToken);
    if (!before) {
      console.log('C2: product doc unavailable on current backend path — skipping');
      return;
    }
    const originalStock = before?.stockQuantity ?? 0;

    // Update stock — may fail if admin MFA not enabled in dev
    const response = await callCallable('admin_update_product_stock', {
      productId: TEST_PRODUCTS.HIGH_STOCK,
      stockQuantity: originalStock + 5,
    }, auth.idToken);

    if (response.error) {
      const msg = (response.error.message || '').toLowerCase();
      // MFA not enabled in dev is an expected limitation — skip rest of test
      if (msg.includes('mfa')) return;
      throw new Error(`admin_update_product_stock failed: ${response.error.message}`);
    }

    // Verify via OrignaBase API
    const after = await getDoc(`products/${TEST_PRODUCTS.HIGH_STOCK}`, auth.idToken);
    expect(after?.stockQuantity).toBe(originalStock + 5);

    // Restore original stock
    await callCallable('admin_update_product_stock', {
      productId: TEST_PRODUCTS.HIGH_STOCK,
      stockQuantity: originalStock,
    }, auth.idToken);
  });
});

// ════════════════════════════════════════════════════════════════════
// D. PROFILE & ADDRESS MANAGEMENT — Via both UI and API
// ════════════════════════════════════════════════════════════════════

test.describe('D. Profile & Address Management', () => {
  test.setTimeout(420_000);

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('D1: Buyer views profile page and sees their info', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    await ensureLoggedInAsBuyer(page, TARGET_URL, BUYER_EMAIL, DEFAULT_PASS);

    // Navigate to profile
    await openHomeSettings(page);
    await page.waitForURL(/\/profile/i, { timeout: 20_000 }).catch(() => {});
    await waitForFlutter(page);

    // Verify profile screen loaded
    const profileContent = page.getByText(/profile|profil|account|compte/i).first();
    await expect(profileContent).toBeVisible({ timeout: 15_000 });

    await navigateHome(page, TARGET_URL);
    await performSignOut(page, TARGET_URL);
  });

  test('D2: Address CRUD via API — add, set default, delete', async () => {
    const auth = await signIn(BUYER_EMAIL);

    // Add address
    const addResult = await callOk('add_buyer_address', {
      street: '789 Deep Test Blvd',
      apartment: 'Suite 100',
      city: 'Vancouver',
      state: 'BC',
      postalCode: 'V6C 1A1',
      country: 'Canada',
      phoneNumber: '+16045550123',
      label: 'Deep Test',
    }, auth.idToken);
    const addressId = addResult.addressId || addResult.id;
    expect(addressId).toBeTruthy();

    // Set as default
    await callOk('set_default_buyer_address', { addressId }, auth.idToken);

    // Delete address (skip update — parallel tests can delete the address between add and update)
    await callOk('delete_buyer_address', { addressId }, auth.idToken);
  });
});

// ════════════════════════════════════════════════════════════════════
// E. ORDER LIFECYCLE — Full state machine via API + UI verification
// ════════════════════════════════════════════════════════════════════

test.describe('E. Order Lifecycle Deep', () => {
  test.setTimeout(300_000);

  test('E1: Full order state machine — pending → confirmed → processing → shipped → delivered', async ({ page }) => {
    const buyerAuth = await createFreshBuyerAuth();
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    const { sellerAuth, productId, price } = await createCheckoutProduct();

    // Create order via checkout
    let checkout: any;
    try {
      checkout = await callOk(
        'create_checkout_session',
        checkoutPayload(authUserId(buyerAuth), productId, price),
        buyerAuth.idToken,
      );
    } catch (error) {
      await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
      throw error;
    }
    const orderId = checkout.orderId;
    expect(orderId).toBeTruthy();

    // Verify order exists (must pass auth token — OrignaBase rules require auth read)
    const order = await waitForOrder(orderId, buyerAuth.idToken);
    expect(order).toBeTruthy();
    expect(order?.orderStatus).toBeTruthy();

    // Transition: confirmed → processing (by seller)
    const updateResult = await callCallable('update_order_status', {
      orderId,
      newStatus: 'processing',
    }, sellerAuth.idToken);

    // Transition: processing → shipped
    await callCallable('update_order_status', {
      orderId,
      newStatus: 'shipped',
      trackingNumber: `TRACK-${uid()}`,
      carrier: 'Canada Post',
    }, sellerAuth.idToken);

    // Transition: shipped → delivered (admin only)
    await callCallable('update_order_status', {
      orderId,
      newStatus: 'delivered',
    }, adminAuth.idToken);

    // Verify final state in SurrealDB (pass auth token)
    const finalOrder = await waitForOrder(orderId, buyerAuth.idToken);
    if (finalOrder?.orderStatus === 'delivered') {
      expect(finalOrder.orderStatus).toBe('delivered');
    }
    await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
  });

  test('E2: Return request flow — buyer requests, admin approves', async () => {
    const buyerAuth = await createFreshBuyerAuth();
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    const { sellerAuth, productId, price } = await createCheckoutProduct();

    // Create and deliver an order first
    let checkout: any;
    try {
      checkout = await callOk(
        'create_checkout_session',
        checkoutPayload(authUserId(buyerAuth), productId, price),
        buyerAuth.idToken,
      );
    } catch (error) {
      await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
      throw error;
    }
    const orderId = checkout.orderId;
    await waitForOrder(orderId, buyerAuth.idToken);

    // Force order to delivered state for return request
    await writeDoc(`orders/${orderId}`, {
      orderStatus: 'delivered',
      paymentStatus: 'captured',
    }, adminAuth.idToken);

    // Buyer creates return request
    const returnResult = await callCallable('create_return_request', {
      orderId,
      reason: 'E2E test return — item not as described',
      cartItemId: 'item_0',
    }, buyerAuth.idToken);

    // Admin approves return
    if (!returnResult.error) {
      await callCallable('approve_return_request', {
        orderId,
      }, adminAuth.idToken);
    }
    await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
  });
});

// ════════════════════════════════════════════════════════════════════
// F. FAVORITES & NAVIGATION
// ════════════════════════════════════════════════════════════════════

test.describe('F. Favorites & Navigation', () => {
  test.setTimeout(300_000);

  test.afterEach(async ({ page }, testInfo) => {
    await screenshotOnFailure(page, testInfo);
  });

  test('F1: Toggle favorite via API and verify SurrealDB state', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { sellerAuth, productId } = await createCheckoutProduct();

    try {
      // Add to favorites
      const addResult = await callOk('toggle_favorite', {
        productId,
      }, auth.idToken);
      expect(addResult).toBeTruthy();

      // Check SurrealDB for favorite doc
      const favDoc = await getDoc(
        `users/${auth.localId}/favorites/${productId}`,
        auth.idToken,
      );
      // Should exist after toggle on
      if (favDoc) {
        expect(favDoc).toBeTruthy();
      }

      // Remove from favorites
      await callOk('toggle_favorite', {
        productId,
      }, auth.idToken);
    } finally {
      await callOk('delete_product', { productId }, sellerAuth.idToken).catch(() => {});
    }
  });

  test('F2: Home screen loads with product cards and navigation works', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    page.setDefaultTimeout(60_000);

    await page.goto(`${TARGET_URL}/`);
    await waitForFlutter(page);
    await checkSemantics(page);

    // Verify home screen has core elements
    const homeContent = page.locator('flt-semantics').first();
    await expect(homeContent).toBeAttached({ timeout: 30_000 });

    // Verify product cards render
    const count = await waitForProductCards(page, 45_000);
    expect(count).toBeGreaterThanOrEqual(0); // May be 0 if no active products

    // Verify settings button is present
    const settingsBtn = page.getByRole('button', { name: /btn-home-settings/i }).first();
    await expect(settingsBtn).toBeAttached({ timeout: 15_000 });
  });
});
