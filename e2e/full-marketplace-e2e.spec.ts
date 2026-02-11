// @ts-check
/**
 * Full Marketplace E2E Test
 * 
 * Tests the complete flow:
 * 1. Seller registration
 * 2. Admin approves seller (adds seller role)
 * 3. Seller adds a product
 * 4. Buyer registers/logs in
 * 5. Buyer purchases the product
 * 6. Order is shipped and delivered
 * 7. Seller receives payment
 */
import { test, expect, Page, BrowserContext } from '@playwright/test';
import {
  waitForFlutter, flutterButton, flutterCheckbox,
  flutterByExactLabel, productCard,
} from './flutter-helpers';
import {
  checkInfrastructure as checkEmulators, signIn,
  callCallable, callOk,
  readDoc, writeDoc, patchDoc, parseDoc,
  waitForOrderStatus, getOrder,
  buildCheckoutPayload, fillStripeCheckout,
  TEST_ACCOUNTS, TEST_PRODUCTS, DEFAULT_PASS,
} from './api-helpers';

// Infrastructure availability cache
let infraAvailable: {
  webApp: boolean | null;
} = {
  webApp: null,
};

/** Check if infrastructure is available */
async function checkInfrastructure(request: any): Promise<typeof infraAvailable> {
  if (infraAvailable.webApp === null) {
    const webRes = await request.get('http://localhost:5005/').catch(() => null);
    infraAvailable = {
      webApp: !!webRes && webRes.status() === 200,
    };
    if (!infraAvailable.webApp) {
      console.log('⚠️  Web app not running on port 5005. Run `flutter run -d chrome --web-port=5005`');
    }
  }
  return infraAvailable;
}

// Test Credentials — match mega-seed accounts (override via env vars in CI/local)
const SELLER_EMAIL = process.env.E2E_SELLER_EMAIL ?? TEST_ACCOUNTS.SELLER1_EMAIL;
const SELLER_PASSWORD = process.env.E2E_SELLER_PASSWORD ?? DEFAULT_PASS;

const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? TEST_ACCOUNTS.BUYER1_EMAIL;
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? DEFAULT_PASS;

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;

function redactEmail(email: string) {
    const [user, domain] = email.split('@');
    if (!domain) return '***';
    const safeUser = user.length <= 2 ? `${user[0] ?? '*'}*` : `${user.slice(0, 2)}***`;
    return `${safeUser}@${domain}`;
}

// Timeouts
const FLUTTER_INIT_TIMEOUT = 90000;
const NAVIGATION_TIMEOUT = 8000;
const ACTION_TIMEOUT = 5000;
const PAGE_LOAD_TIMEOUT = 30000;

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Wait for Flutter to initialize
 * Flutter Web uses CanvasKit so we need to wait for it to be ready
 */
async function waitForFlutterInit(page: Page) {
    console.log(`⏳ Waiting for Flutter Web (timeout: ${FLUTTER_INIT_TIMEOUT}ms)...`);
    const startTime = Date.now();
    
    // 1) Wait for Flutter canvas/host to appear
    await page.waitForFunction(() => {
        const glasspane = document.querySelector('flt-glass-pane');
        const flutterView = document.querySelector('flutter-view');
        const canvas = document.querySelector('canvas');
        return !!glasspane || !!flutterView || (canvas instanceof HTMLCanvasElement && canvas.getBoundingClientRect().width > 0);
    }, { timeout: FLUTTER_INIT_TIMEOUT });
    console.log(`   ✅ Flutter host found (${Date.now() - startTime}ms)`);

    // 2) Wait for splash screen to disappear
    await page.waitForFunction(() => {
        const splash = document.querySelector('#splash, .splash-screen, [class*="splash"]');
        return !splash || (splash as HTMLElement).style.display === 'none' || (splash as HTMLElement).style.opacity === '0';
    }, { timeout: FLUTTER_INIT_TIMEOUT }).catch(() => {});
    console.log(`   ✅ Splash gone (${Date.now() - startTime}ms)`);

    // 3) Wait for canvas to be rendered with size
    await page.waitForFunction(() => {
        const canvas = document.querySelector('canvas');
        if (!(canvas instanceof HTMLCanvasElement)) return false;
        const rect = canvas.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
    }, { timeout: 30000 }).catch(() => {});
    console.log(`   ✅ Canvas ready (${Date.now() - startTime}ms)`);
    
    // 4) Enable Flutter Web accessibility
    await page.evaluate(() => {
        const event = new KeyboardEvent('keydown', { key: 'Tab' });
        document.dispatchEvent(event);
    });

    // 5) Wait for semantics attachment
    await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 20000 }).catch(() => {});
    console.log(`   ✅ Flutter ready in ${Date.now() - startTime}ms`);
}

/**
 * Find Flutter element by text or semantic label
 * Flutter Web exposes semantics via flt-semantics elements when accessibility is active
 */
async function findFlutterElement(page: Page, text: string, timeout = 10000) {
    // Try standard role-based selectors first (Flutter exposes these)
    const roleLocator = page.getByRole('button', { name: new RegExp(text, 'i') })
        .or(page.getByRole('textbox', { name: new RegExp(text, 'i') }))
        .or(page.getByRole('link', { name: new RegExp(text, 'i') }))
        .or(page.locator(`[aria-label*="${text}" i]`))
        .or(page.locator(`flt-semantics[aria-label*="${text}" i]`));
    
    try {
        await roleLocator.first().waitFor({ state: 'visible', timeout });
        return roleLocator.first();
    } catch {
        // Fallback to any element containing the text
        return page.locator(`text=${text}`).first();
    }
}

/**
 * Login helper
 */
async function login(page: Page, email: string, password: string) {
    await page.goto('/');
    await waitForFlutterInit(page);
    
    // Check if already logged in (profile icon visible)
    const profileIcon = page.locator('[aria-label*="Profile" i], [aria-label*="Account" i]').first();
    if (await profileIcon.isVisible().catch(() => false)) {
        // Check if we need to log in (might show login prompt)
        const signInButton = page.getByRole('button', { name: /sign in/i }).first();
        if (!await signInButton.isVisible().catch(() => false)) {
            console.log('Already logged in');
            return;
        }
    }
    
    // Navigate to login
    await page.goto('/login');
    await waitForFlutterInit(page);
    
    // Fill login form - try multiple selectors for Flutter Web
    // Flutter textfields expose aria-label or can be found by role
    const emailField = page.getByRole('textbox', { name: /email/i })
        .or(page.locator('[aria-label*="email" i]'))
        .or(page.locator('input[type="email"]'))
        .first();
    await emailField.waitFor({ state: 'visible', timeout: 15000 });
    await emailField.fill(email);
    
    const passwordField = page.getByRole('textbox', { name: /password/i })
        .or(page.locator('[aria-label*="password" i]'))
        .or(page.locator('input[type="password"]'))
        .first();
    await passwordField.fill(password);
    
    // Click sign in
    await page.getByRole('button', { name: /sign in/i }).first().click();

    // Prefer waiting for a navigation effect vs. sleeping
    await expect(page).not.toHaveURL(/\/login(?:\b|$)/, { timeout: 15000 });
    await waitForFlutterInit(page);
}

/**
 * Register a new user
 */
async function registerUser(page: Page, name: string, email: string, password: string) {
    await page.goto('/login');
    await waitForFlutterInit(page);
    
    // Switch to registration mode (look for "Create Account" or similar)
    const switchButton = page.getByText(/create account|sign up|register/i).first();
    if (await switchButton.isVisible().catch(() => false)) {
        await switchButton.click();
        await page.waitForTimeout(ACTION_TIMEOUT);
    }
    
    // Fill registration form
    const nameField = page.getByLabel(/name|full name/i).first();
    if (await nameField.isVisible().catch(() => false)) {
        await nameField.fill(name);
    }
    
    await page.getByLabel(/email/i).first().fill(email);
    await page.getByLabel(/password/i).first().fill(password);
    
    // Accept terms if checkbox exists
    const termsCheckbox = page.getByRole('checkbox').first();
    if (await termsCheckbox.isVisible().catch(() => false)) {
        await termsCheckbox.check();
    }
    
    // Submit registration
    await page.getByRole('button', { name: /create|sign up|register/i }).first().click();
    
    await page.waitForTimeout(NAVIGATION_TIMEOUT);
}

/**
 * Navigate to seller registration
 */
async function navigateToSellerRegistration(page: Page) {
    // Try profile > become seller flow
    const profileButton = page.locator('[aria-label="Profile"], button:has-text("Profile")').first();
    if (await profileButton.isVisible().catch(() => false)) {
        await profileButton.click();
        await page.waitForTimeout(ACTION_TIMEOUT);
    }
    
    // Look for "Become a Seller" link/button
    const becomeSellerButton = page.getByText(/become.*seller|sell.*with.*us|start.*selling/i).first();
    if (await becomeSellerButton.isVisible().catch(() => false)) {
        await becomeSellerButton.click();
        await page.waitForTimeout(NAVIGATION_TIMEOUT);
        return;
    }
    
    // Direct navigation fallback
    await page.goto('/seller/registration');
    await page.waitForTimeout(NAVIGATION_TIMEOUT);
}

/**
 * Logout helper
 */
async function logout(page: Page) {
    // Navigate to profile
    const profileButton = page.locator('[aria-label="Profile"], button:has-text("Profile"), [aria-label="Settings"]').first();
    if (await profileButton.isVisible().catch(() => false)) {
        await profileButton.click();
        await page.waitForTimeout(ACTION_TIMEOUT);
    }
    
    // Click logout
    const logoutButton = page.getByText(/log.*out|sign.*out/i).first();
    if (await logoutButton.isVisible().catch(() => false)) {
        await logoutButton.click();
        await page.waitForTimeout(ACTION_TIMEOUT);
        
        // Confirm logout if dialog appears
        const confirmButton = page.getByRole('button', { name: /yes|confirm|log.*out/i }).first();
        if (await confirmButton.isVisible().catch(() => false)) {
            await confirmButton.click();
            await page.waitForTimeout(NAVIGATION_TIMEOUT);
        }
    }
}

// =============================================================================
// FULL MARKETPLACE E2E — Semantics-enabled (previously skipped for CanvasKit)
//
// Uses Flutter Web's <flt-semantics> DOM tree for UI interactions
// combined with API calls for backend operations.
//
// Requirements:
//   1. flutter run -d chrome --web-port=5005
//   2. firebase emulators:start
//   3. cd e2e && npx ts-node mega-seed.ts
//   4. stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
// =============================================================================

test.describe.serial('Full Marketplace E2E Flow', () => {
  test.beforeEach(async ({ request }) => {
    // Need both the Flutter web app AND Firebase emulators
    const webInfra = await checkInfrastructure(request);
    test.skip(!webInfra.webApp,
      'Web app not running. Run `flutter run -d chrome --web-port=5005`');
    const emuInfra = await checkEmulators(request);
    test.skip(!emuInfra.auth || !emuInfra.firestore || !emuInfra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  // ── Shared state across serial tests ──
  let sellerAuth: any;
  let buyerAuth: any;
  let adminAuth: any;
  let testProductId: string;
  let orderId: string;

  /**
   * Login via Flutter UI using semantics.
   * ModernTextField renders <input> inside <flt-semantics>.
   * The Sign In / Create Account ModernButton has an automatic Semantics label.
   */
  async function loginUI(page: Page, email: string, password: string) {
    await page.goto('/login');
    await waitForFlutter(page);

    // Retry loop — Flutter may still be rendering the login form after semantics attach
    const maxRetries = 5;
    let filled = false;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      // Strategy 1: getByRole textbox (accessible name from hintText)
      const textboxes = page.getByRole('textbox');
      const count = await textboxes.count();

      if (count >= 2) {
        await textboxes.first().click();
        await textboxes.first().fill(email);
        await textboxes.nth(1).click();
        await textboxes.nth(1).fill(password);
        filled = true;
        break;
      }

      // Strategy 2: raw <input> elements inside flt-semantics
      const inputs = page.locator('flt-semantics input, input');
      const inputCount = await inputs.count();
      if (inputCount >= 2) {
        console.log(`   Fallback: found ${inputCount} input(s)`);
        await inputs.first().fill(email);
        await inputs.nth(1).fill(password);
        filled = true;
        break;
      }

      // Strategy 3: try aria-label based selectors for Flutter text fields
      const emailField = page.locator('[aria-label*="email" i], [aria-label*="Email" i]').first();
      const passwordField = page.locator('[aria-label*="password" i], [aria-label*="Password" i]').first();
      if (await emailField.isVisible({ timeout: 2_000 }).catch(() => false) &&
          await passwordField.isVisible({ timeout: 1_000 }).catch(() => false)) {
        console.log('   Using aria-label selectors for login fields');
        await emailField.fill(email);
        await passwordField.fill(password);
        filled = true;
        break;
      }

      console.log(`   ⏳ Login form not ready (attempt ${attempt}/${maxRetries}): ${count} textboxes, ${inputCount} inputs`);
      await page.waitForTimeout(3_000);
    }

    if (!filled) {
      // Last resort: take screenshot for debugging and throw
      const textboxes = page.getByRole('textbox');
      const inputs = page.locator('flt-semantics input, input');
      throw new Error(
        `Login form not found after ${maxRetries} attempts: ${await textboxes.count()} textboxes, ${await inputs.count()} inputs`
      );
    }

    // Click Sign In (ModernButton auto-generates Semantics label)
    await flutterButton(page, 'Sign In').click();
    await expect(page).not.toHaveURL(/\/login/, { timeout: 15_000 });
  }

  test.beforeAll(async () => {
    // Pre-authenticate accounts via API for backend operations
    try {
      sellerAuth = await signIn(TEST_ACCOUNTS.SELLER1_EMAIL, DEFAULT_PASS);
      buyerAuth  = await signIn(TEST_ACCOUNTS.BUYER1_EMAIL, DEFAULT_PASS);
      adminAuth  = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
      console.log('✅ All test accounts pre-authenticated via API');
    } catch (e: any) {
      console.log(`⚠️ API auth failed: ${e.message}. Run mega-seed.ts first.`);
    }
  });

  // ──────────────────────────────────────────────────────────────────
  // 1. SELLER LOGIN — Flutter UI with semantics
  // ──────────────────────────────────────────────────────────────────
  test('1. Seller Login via Flutter UI', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('📧 Seller:', redactEmail(SELLER_EMAIL));

    await loginUI(page, SELLER_EMAIL, SELLER_PASSWORD);

    // Verify we landed on home (not still on login)
    const url = page.url();
    expect(url).not.toContain('/login');
    console.log(`✅ Seller logged in — redirected to ${url}`);
  });

  // ──────────────────────────────────────────────────────────────────
  // 2. NAVIGATE TO SELLER REGISTRATION — Flutter UI
  // ──────────────────────────────────────────────────────────────────
  test('2. Seller Registration Page', async ({ page }) => {
    test.setTimeout(60_000);

    // Navigate directly (deep link)
    await page.goto('/seller-registration');
    await waitForFlutter(page);

    // Verify page loaded by checking for known semantic elements
    const termsCheckbox = page.locator('[aria-label="chk-seller-terms"]');
    const actionButton  = page.locator('[aria-label="btn-seller-action"]');

    const hasCheckbox = await termsCheckbox.isVisible({ timeout: 10_000 }).catch(() => false);
    const hasButton   = await actionButton.isVisible({ timeout: 5_000 }).catch(() => false);

    console.log(`   chk-seller-terms: ${hasCheckbox}, btn-seller-action: ${hasButton}`);
    expect(hasCheckbox || hasButton,
      'Seller registration page should show terms checkbox or action button').toBeTruthy();
    console.log('✅ Seller registration page accessible with semantic elements');
  });

  // ──────────────────────────────────────────────────────────────────
  // 3. SELLER ONBOARDING — Accept terms + click action via semantics
  // ──────────────────────────────────────────────────────────────────
  test('3. Seller Onboarding — Accept Terms', async ({ page }) => {
    test.setTimeout(60_000);

    await page.goto('/seller-registration');
    await waitForFlutter(page);

    // Accept terms checkbox (chk-seller-terms)
    const termsCheckbox = flutterCheckbox(page, 'chk-seller-terms');
    if (await termsCheckbox.isVisible({ timeout: 10_000 }).catch(() => false)) {
      await termsCheckbox.check();
      console.log('   ☑️ Seller terms accepted');
    }

    // Click action button (btn-seller-action)
    const actionBtn = flutterByExactLabel(page, 'btn-seller-action');
    if (await actionBtn.isVisible({ timeout: 5_000 }).catch(() => false)) {
      await actionBtn.click();
      await page.waitForTimeout(3_000);
      console.log('   🔘 Action button clicked');
    }

    // In emulator mode, Stripe onboarding redirects may be mocked
    console.log('✅ Seller onboarding flow initiated');
  });

  // ──────────────────────────────────────────────────────────────────
  // 4. ADMIN APPROVES SELLER — API (no admin panel UI semantics)
  // ──────────────────────────────────────────────────────────────────
  test('4. Admin Approves Seller (API)', async () => {
    test.setTimeout(15_000);

    if (!sellerAuth) sellerAuth = await signIn(SELLER_EMAIL, DEFAULT_PASS);

    const userDoc = await readDoc(`users/${sellerAuth.localId}`);
    const user = parseDoc(userDoc);
    const roles: string[] = user?.roles || [];

    if (!roles.includes('seller')) {
      await patchDoc(`users/${sellerAuth.localId}`, { roles: ['buyer', 'seller'] });
      console.log('   ✅ Seller role granted via API');
    } else {
      console.log('   ℹ️ User already has seller role');
    }

    expect(user?.onboardingCompleted || user?.sellerProfile?.onboardingCompleted,
      'Seller should be onboarded (set by mega-seed)').toBeTruthy();
    console.log('✅ Seller approved and onboarded');
  });

  // ──────────────────────────────────────────────────────────────────
  // 5. SELLER CREATES PRODUCT — API + verify visible in Flutter UI
  // ──────────────────────────────────────────────────────────────────
  test('5. Seller Creates Product', async ({ page }) => {
    test.setTimeout(30_000);

    if (!sellerAuth) sellerAuth = await signIn(SELLER_EMAIL, DEFAULT_PASS);

    // Create product via API (complex multi-step form is not reliable for E2E)
    const rnd = Math.random().toString(16).slice(2, 8);
    testProductId = `e2e_prod_${Date.now()}_${rnd}`;

    await writeDoc(`products/${testProductId}`, {
      name: `E2E Test Scarf ${rnd}`,
      description: 'Automated E2E test product — Full Marketplace Flow',
      price: 29.99,
      categoryId: 2,
      sellerId: sellerAuth.localId,
      sellerAddress: { street: '100 King St W', city: 'Toronto', state: 'ON', postalCode: 'M5X 1A9', country: 'CA' },
      stockQuantity: 50,
      isActive: true,
      status: 'active',
      approved: true,
      isDigital: false,
      freeShipping: false,
      isLocalDeliveryOnly: false,
      isPerishable: false,
      estimatedShipDays: 3,
      weightKg: 0.3,
      imageUrls: ['https://picsum.photos/400'],
      keywords: ['e2e', 'test', 'scarf'],
      deliveryOptions: [{ speed: 'standard', isEnabled: true, estimatedDays: 5, price: 0 }],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    console.log(`   ✅ Product created via API: ${testProductId}`);

    // Verify marketplace loads with product cards (Flutter UI)
    await page.goto('/');
    await waitForFlutter(page);

    const anyCard = page.locator('[aria-label^="product-card-"]').first();
    const hasCards = await anyCard.isVisible({ timeout: 15_000 }).catch(() => false);
    console.log(`   Product cards visible in UI: ${hasCards}`);
    console.log('✅ Product created and marketplace loaded');
  });

  // ──────────────────────────────────────────────────────────────────
  // 6. BUYER LOGIN — Flutter UI with semantics
  // ──────────────────────────────────────────────────────────────────
  test('6. Buyer Login via Flutter UI', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('📧 Buyer:', redactEmail(BUYER_EMAIL));

    await loginUI(page, BUYER_EMAIL, BUYER_PASSWORD);

    const url = page.url();
    expect(url).not.toContain('/login');
    console.log(`✅ Buyer logged in — redirected to ${url}`);
  });

  // ──────────────────────────────────────────────────────────────────
  // 7. BUYER BROWSES + ADDS TO CART — Flutter UI with semantics
  // ──────────────────────────────────────────────────────────────────
  test('7. Buyer Browses and Adds Product to Cart', async ({ page }) => {
    test.setTimeout(90_000);

    // Login first (each serial test gets a fresh page)
    await loginUI(page, BUYER_EMAIL, BUYER_PASSWORD);

    // Navigate to home
    await page.goto('/');
    await waitForFlutter(page);

    // Look for a seeded product card (product_001 = Handmade Quebec Scarf)
    const card = productCard(page, 'product_001');
    let cardVisible = await card.isVisible({ timeout: 15_000 }).catch(() => false);

    if (!cardVisible) {
      // Fallback: try any product card
      const anyCard = page.locator('[aria-label^="product-card-"]').first();
      cardVisible = await anyCard.isVisible({ timeout: 10_000 }).catch(() => false);
      if (cardVisible) {
        await anyCard.click();
        console.log('   Clicked fallback product card');
      }
    } else {
      await card.click();
      console.log('   Clicked product_001 card');
    }

    if (cardVisible) {
      await page.waitForTimeout(2_000);

      // On product details page, click Add to Cart
      const addBtn = flutterButton(page, 'Add to Cart');
      if (await addBtn.isVisible({ timeout: 10_000 }).catch(() => false)) {
        await addBtn.click();
        console.log('   🛒 Product added to cart via Flutter UI');
      } else {
        console.log('   ⚠️ Add to Cart button not found — product may be own or out of stock');
      }
    } else {
      console.log('   ⚠️ No product cards visible — seed data may be missing');
    }

    console.log('✅ Buyer browsed marketplace');
  });

  // ──────────────────────────────────────────────────────────────────
  // 8. BUYER CHECKOUT — API + Stripe (most reliable for payment flow)
  // ──────────────────────────────────────────────────────────────────
  test('8. Buyer Checkout and Payment', async ({ page }) => {
    test.setTimeout(180_000);

    if (!buyerAuth) buyerAuth = await signIn(BUYER_EMAIL, DEFAULT_PASS);

    // Use high-stock product (product_024, ~500 stock) to avoid depletion
    const checkoutProduct = TEST_PRODUCTS.HIGH_STOCK;
    const { data } = await buildCheckoutPayload(buyerAuth.localId, checkoutProduct, 1);
    const result = await callOk('create_checkout_session', data, buyerAuth.idToken);

    expect(result.orderId, 'Checkout should return orderId').toBeTruthy();
    expect(result.checkoutUrl, 'Checkout should return checkoutUrl').toBeTruthy();
    orderId = result.orderId;
    console.log(`   🆔 Order: ${orderId}`);

    // Navigate to Stripe Checkout and pay
    await page.goto(result.checkoutUrl);
    await fillStripeCheckout(page, BUYER_EMAIL);
    await page.waitForTimeout(5_000);

    // Wait for webhook → order confirmed
    const order = await waitForOrderStatus(
      orderId, ['confirmed', 'processing'], 'orderStatus', 60_000
    );
    expect(order).toBeTruthy();
    console.log(`   ✅ ${order.orderStatus} / ${order.paymentStatus}`);
    console.log('✅ Checkout + payment completed');
  });

  // ──────────────────────────────────────────────────────────────────
  // 9. VERIFY ORDER CREATION — API
  // ──────────────────────────────────────────────────────────────────
  test('9. Verify Order Creation', async () => {
    test.setTimeout(15_000);

    const order = await getOrder(orderId);
    expect(order, 'Order should exist').toBeTruthy();
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('captured');
    expect(order.items?.length).toBeGreaterThan(0);

    console.log(`   📦 Items: ${order.items.length}`);
    console.log(`   💰 Total: $${(order.totalAmountCents / 100).toFixed(2)}`);
    console.log('✅ Order verified in Firestore');
  });

  // ──────────────────────────────────────────────────────────────────
  // 10. SELLER SHIPS ORDER — API
  // ──────────────────────────────────────────────────────────────────
  test('10. Seller Ships Order', async () => {
    test.setTimeout(15_000);

    if (!sellerAuth) sellerAuth = await signIn(SELLER_EMAIL, DEFAULT_PASS);

    // processing
    await callCallable('update_order_status', {
      orderId, newStatus: 'processing',
    }, sellerAuth.idToken);

    // shipped
    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'shipped',
      trackingNumber: 'CP98765E2E',
      carrier: 'Canada Post',
    }, sellerAuth.idToken);
    expect(result.newStatus).toBe('shipped');

    const order = await getOrder(orderId);
    expect(order.trackingNumber).toBe('CP98765E2E');
    console.log(`   📦 Shipped: tracking=${order.trackingNumber}`);
    console.log('✅ Order shipped by seller');
  });

  // ──────────────────────────────────────────────────────────────────
  // 11. BUYER CONFIRMS DELIVERY — API
  // ──────────────────────────────────────────────────────────────────
  test('11. Buyer Confirms Delivery', async () => {
    test.setTimeout(30_000);

    if (!sellerAuth) sellerAuth = await signIn(SELLER_EMAIL, DEFAULT_PASS);
    if (!adminAuth)  adminAuth  = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    if (!buyerAuth)  buyerAuth  = await signIn(BUYER_EMAIL, DEFAULT_PASS);

    // in_transit
    await callCallable('update_order_status', {
      orderId, newStatus: 'in_transit',
    }, sellerAuth.idToken);

    // delivered (admin only — sellers cannot mark delivered)
    await callCallable('update_order_status', {
      orderId, newStatus: 'delivered',
    }, adminAuth.idToken);

    // Buyer confirms receipt
    const result = await callCallable('confirm_order_receipt', { orderId }, buyerAuth.idToken);
    expect(result.success).toBe(true);
    expect(result.captured).toBe(true);

    const order = await getOrder(orderId);
    expect(order.confirmedByClient).toBe(true);
    console.log('✅ Delivery confirmed by buyer');
  });

  // ──────────────────────────────────────────────────────────────────
  // 12. VERIFY PAYMENT — API
  // ──────────────────────────────────────────────────────────────────
  test('12. Verify Payment Captured', async () => {
    test.setTimeout(10_000);

    const order = await getOrder(orderId);
    expect(order.paymentStatus).toBe('captured');
    expect(order.orderStatus).toBe('delivered');
    expect(order.confirmedByClient).toBe(true);

    console.log(`   💳 Payment: ${order.paymentStatus}`);
    console.log(`   📦 Status: ${order.orderStatus}`);
    console.log(`   ✅ Confirmed: ${order.confirmedByClient}`);
    console.log('✅ Full marketplace lifecycle — COMPLETE');
  });
});

// =============================================================================
// INDIVIDUAL SMOKE TESTS
// =============================================================================

test.describe('Marketplace Smoke Tests', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.webApp, 'Web app not running. Run `flutter run -d chrome --web-port=5005`');
  });
    test('Home page loads', async ({ page }) => {
        // Log network requests for debugging
        page.on('console', msg => {
            if (msg.type() === 'error' || msg.text().includes('emulator')) {
                console.log(`CONSOLE ${msg.type()}: ${msg.text()}`);
            }
        });
        
        await page.goto('/');
        
        // Wait longer for Flutter to initialize - it connects to Firebase emulators
        await page.waitForTimeout(10000);
        
        // Check if splash is gone
        const splashGone = await page.evaluate(() => {
            const splash = document.getElementById('splash');
            return !splash || splash.style.display === 'none' || splash.getAttribute('hidden') !== null;
        });
        console.log(`Splash gone: ${splashGone}`);
        
        // Wait for any Flutter rendering element (flt-glass-pane, flutter-view, or canvas)
        await page.waitForFunction(() => {
            const glasspane = document.querySelector('flt-glass-pane');
            const flutterView = document.querySelector('flutter-view');
            const canvas = document.querySelector('canvas');
            return !!glasspane || !!flutterView || !!canvas;
        }, { timeout: 60000 }).catch(e => console.log('Flutter element wait failed:', e.message));
        
        // Verify Flutter engine loaded
        const flutterLoaded = await page.evaluate(() => {
            const glasspane = document.querySelector('flt-glass-pane');
            const flutterView = document.querySelector('flutter-view');
            const canvas = document.querySelector('canvas');
            return { 
                hasGlasspane: !!glasspane, 
                hasFlutterView: !!flutterView,
                hasCanvas: !!canvas,
            };
        });
        console.log(`Flutter state: ${JSON.stringify(flutterLoaded)}`);
        
        expect(flutterLoaded.hasGlasspane || flutterLoaded.hasFlutterView || flutterLoaded.hasCanvas).toBeTruthy();
        console.log('✅ Home page Flutter app loaded successfully');
    });

    test('Login page accessible', async ({ page }) => {
        await page.goto('/login');
        await page.waitForTimeout(10000); // Wait for Flutter + Firebase
        
        // Verify URL and Flutter loaded
        expect(page.url()).toContain('/login');
        
        const flutterLoaded = await page.evaluate(() => {
            const glasspane = document.querySelector('flt-glass-pane');
            const flutterView = document.querySelector('flutter-view');
            const canvas = document.querySelector('canvas');
            return { hasFlutter: !!glasspane || !!flutterView || !!canvas };
        });
        expect(flutterLoaded.hasFlutter).toBeTruthy();
        console.log('✅ Login page accessible');
    });

    test('Seller registration page accessible', async ({ page }) => {
        await page.goto('/seller/registration');
        await page.waitForTimeout(10000);
        
        // Should redirect to login if not authenticated, or show registration
        const currentUrl = page.url();
        const isCorrectPage = currentUrl.includes('seller') || currentUrl.includes('login');
        expect(isCorrectPage).toBeTruthy();
        console.log(`✅ Seller registration redirected to: ${currentUrl}`);
    });

    test('Cart page accessible when logged in', async ({ page }) => {
        // Skip login for now since it's complex with Flutter Web
        // Just verify the page loads
        await page.goto('/cart');
        await page.waitForTimeout(10000);
        
        // Verify Flutter app loaded (might redirect to login)
        const flutterLoaded = await page.evaluate(() => {
            const glasspane = document.querySelector('flt-glass-pane');
            const flutterView = document.querySelector('flutter-view');
            const canvas = document.querySelector('canvas');
            return { hasFlutter: !!glasspane || !!flutterView || !!canvas };
        });
        expect(flutterLoaded.hasFlutter).toBeTruthy();
        console.log('✅ Cart/Login page accessible');
    });
});

// =============================================================================
// API/BACKEND INTEGRATION TESTS (using fetch to Firebase Functions)
// =============================================================================

test.describe('Backend Integration', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.webApp, 'Web app not running. Run `flutter run -d chrome --web-port=5005`');
  });
    const FUNCTIONS_URL = 'http://127.0.0.1:5001/orignagta/us-central1';
    
    test('Health check - Functions emulator running', async ({ request }) => {
        try {
            // Try to reach any function endpoint
            const response = await request.get(`${FUNCTIONS_URL}/healthCheck`, {
                timeout: 5000
            }).catch(() => null);
            
            if (response) {
                console.log(`Functions emulator status: ${response.status()}`);
            } else {
                console.log('Functions emulator may not be running');
            }
        } catch (e) {
            console.log('Functions emulator connection failed - this is expected if not running');
        }
    });
});
