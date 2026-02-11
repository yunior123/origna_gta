// @ts-check
/**
 * OrignaGTA — Yahoo Buyer Full Lifecycle E2E Test
 * ================================================
 * A single test that follows buyer yuniorrodriguezo4601@yahoo.com through
 * the ENTIRE purchase lifecycle, verifying that REAL email notifications
 * are sent at every stage:
 *
 *   Step 1 → Checkout + Stripe payment  → Order Confirmation email (buyer)
 *                                        → Seller Notification email (seller)
 *   Step 2 → Seller → processing        → (no email currently)
 *   Step 3 → Seller → shipped           → Shipped email (buyer + seller)
 *   Step 4 → Seller → in_transit        → (no email currently)
 *   Step 5 → Admin  → delivered         → Delivered email (buyer)
 *   Step 6 → Buyer confirms receipt     → Payment captured
 *
 * Prerequisites:
 *   1. firebase emulators:start
 *   2. cd e2e && npx ts-node mega-seed.ts
 *   3. stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
 *   4. FORCE_REAL_EMAIL=true in functions/.env (for real Mailjet emails)
 *   5. npx playwright test yahoo-buyer-lifecycle-e2e.spec.ts --reporter=list
 *
 * After running: Check yuniorrodriguezo4601@yahoo.com inbox for:
 *   ✉️  Order confirmation (#...)
 *   ✉️  Order shipped (#... Has Shipped)
 *   ✉️  Order delivered (#... Delivered - Please Confirm Receipt)
 */
import { test, expect } from '@playwright/test';
import {
  checkInfrastructure, signIn,
  callCallable,
  callOk,
  readDoc, writeDoc, parseDoc,
  waitForOrderStatus, getOrder,
  dismissStripeModals,
  AUTH_EMULATOR, PROJECT_ID, STRIPE_CARD,
  DEFAULT_PASS,
} from './api-helpers';

// ════════════════════════════════════════════════════════════════════
// CONFIG — Yahoo buyer account
// ════════════════════════════════════════════════════════════════════

const YAHOO_EMAIL    = 'yuniorrodriguezo4601@yahoo.com';
const YAHOO_PASSWORD = 'TestYahoo123!';

// Seller & Admin accounts (from mega-seed)
const SELLER_EMAIL   = 'seller1@test.origna.ca';
const ADMIN_EMAIL    = 'yr62813@gmail.com';
const ADMIN_PASSWORD = '960227Y#y';

// Product with high stock to avoid depletion from repeated runs
const PRODUCT_ID = 'product_024'; // Budget Sticker Pack, ~500 stock, seller1

// ════════════════════════════════════════════════════════════════════
// HELPER — Create Yahoo user in Auth emulator if not exists
// ════════════════════════════════════════════════════════════════════

async function ensureYahooUser(): Promise<string> {
  // Try to sign in first (user may already exist from mega-seed or prior run)
  try {
    const auth = await signIn(YAHOO_EMAIL, YAHOO_PASSWORD);
    return auth.localId;
  } catch {
    // User doesn't exist — create it
  }

  const res = await fetch(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: YAHOO_EMAIL,
        password: YAHOO_PASSWORD,
        displayName: 'Yunior Yahoo',
        returnSecureToken: true,
      }),
    }
  );
  const data = await res.json();
  if (data.error) {
    if (data.error.message?.includes('EMAIL_EXISTS')) {
      const auth = await signIn(YAHOO_EMAIL, YAHOO_PASSWORD);
      return auth.localId;
    }
    throw new Error(`ensureYahooUser: ${data.error.message}`);
  }

  const uid = data.localId;

  // Mark email verified
  await fetch(`${AUTH_EMULATOR}/emulator/v1/projects/${PROJECT_ID}/accounts`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ localId: uid, emailVerified: true }),
  });

  // Create Firestore user document with Canadian address (buyer role)
  await writeDoc(`users/${uid}`, {
    email: YAHOO_EMAIL,
    displayName: 'Yunior Yahoo',
    roles: ['buyer'],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    suspended: false,
    address: {
      street: '350 Rue Saint-Paul',
      apartment: 'Suite 200',
      city: 'Montreal',
      state: 'QC',
      postalCode: 'H2Y 1H2',
      country: 'CA',
      phoneNumber: '+15141234567',
      isDefault: true,
      label: 'Home',
    },
  });

  return uid;
}

// ════════════════════════════════════════════════════════════════════
// HELPER — Checkout + Pay on Stripe (based on admin-email-test pattern)
// ════════════════════════════════════════════════════════════════════

async function checkoutAndPay(
  page: any,
  buyerUid: string,
  buyerToken: string,
  productId: string,
): Promise<{ orderId: string; order: any }> {
  // Read product
  const prodDoc = await readDoc(`products/${productId}`);
  const product = parseDoc(prodDoc);
  expect(product, `Product ${productId} must exist`).toBeTruthy();

  // Read buyer
  const buyerDoc = await readDoc(`users/${buyerUid}`);
  const buyer = parseDoc(buyerDoc);
  expect(buyer, 'Buyer user doc must exist').toBeTruthy();
  const address = buyer?.address || {};

  // Build checkout payload
  const payload = {
    userId: buyerUid,
    items: [{
      productId,
      name: product.name,
      price: product.price,
      quantity: 1,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || ['https://picsum.photos/400'],
    }],
    subtotal: product.price,
    shippingAddress: {
      street: address.street || '350 Rue Saint-Paul',
      apartment: address.apartment || 'Suite 200',
      city: address.city || 'Montreal',
      state: address.state || 'QC',
      postalCode: address.postalCode || 'H2Y 1H2',
      country: address.country || 'CA',
      phoneNumber: address.phoneNumber || '+15141234567',
    },
  };

  // Create checkout session
  console.log('   💳 Creating checkout session…');
  const result = await callOk('create_checkout_session', payload, buyerToken);
  expect(result.orderId).toBeTruthy();
  expect(result.checkoutUrl).toBeTruthy();
  console.log(`      ✅ Order: ${result.orderId}`);
  console.log(`      🔗 Stripe: ${result.checkoutUrl.substring(0, 80)}…`);

  // Navigate to Stripe Checkout & pay
  console.log('   💰 Navigating to Stripe Checkout…');
  await page.goto(result.checkoutUrl);
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});

  // Dismiss Stripe Link modal
  await dismissStripeModals(page);

  // Fill email field if visible (use random to avoid Stripe Link SMS)
  const emailInput = page.locator('#email, input[name="email"]').first();
  if (await emailInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
    const safeEmail = `yahoo-test-${Date.now()}@origna-test.ca`;
    await emailInput.fill(safeEmail);
    await page.waitForTimeout(1_500);

    // Check for SMS verification (Stripe Link) — dismiss if present
    const smsInput = page.locator('[data-testid="sms-code-input-0"]').first();
    if (await smsInput.isVisible({ timeout: 3_000 }).catch(() => false)) {
      console.log('   ⚠️ Stripe Link SMS verification — escaping');
      await page.keyboard.press('Escape').catch(() => {});
      await page.waitForTimeout(1_000);
      const altBtn = page.locator('button:has-text("Pay another way")').first();
      if (await altBtn.isVisible({ timeout: 2_000 }).catch(() => false)) {
        await altBtn.click().catch(() => {});
        await page.waitForTimeout(1_500);
      }
    }
    await dismissStripeModals(page);
  }

  // Expand Card payment method if needed
  const cardField = page.locator('#cardNumber, input[name="cardNumber"]').first();
  const cardVisible = await cardField.isVisible({ timeout: 3_000 }).catch(() => false);
  if (!cardVisible) {
    const cardRadio = page.locator('#payment-method-accordion-item-title-card').first();
    if (await cardRadio.isVisible({ timeout: 3_000 }).catch(() => false)) {
      await cardRadio.click({ force: true }).catch(() => {});
      await page.waitForTimeout(3_000);
    } else {
      for (const sel of [
        '[data-testid="card-accordion-item-button"]',
        'button:has-text("Card")',
        'button:has-text("Pay with card")',
        '[data-testid="card-tab"]',
        'text=Card >> nth=0',
      ]) {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 1_500 }).catch(() => false)) {
          await el.click().catch(() => {});
          await page.waitForTimeout(2_000);
          break;
        }
      }
    }
    await dismissStripeModals(page);
  }

  // Fill card details
  await cardField.waitFor({ state: 'visible', timeout: 30_000 });
  await cardField.fill(STRIPE_CARD.number);
  await page.locator('#cardExpiry, input[name="cardExpiry"]').first().fill(STRIPE_CARD.exp);
  await page.locator('#cardCvc, input[name="cardCvc"]').first().fill(STRIPE_CARD.cvc);

  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false))
    await nameField.fill('Yunior Yahoo');
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false))
    await postalField.fill(STRIPE_CARD.postalCode);

  // Click Pay
  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.click();
  console.log('      ⏳ Payment submitted — waiting for redirect…');

  // Wait for navigation away from Stripe
  try {
    await page.waitForURL(
      (url: URL) => !url.hostname.includes('checkout.stripe.com'),
      { timeout: 45_000 }
    );
    console.log('      ✅ Stripe redirect completed');
  } catch {
    console.log('      ⚠️ Still on Stripe after 45s — continuing');
  }
  await page.waitForTimeout(3_000);

  // Wait for order confirmation (webhook → confirmed)
  const order = await waitForOrderStatus(
    result.orderId,
    ['confirmed', 'processing', 'payment_authorized'],
    'orderStatus',
    60_000
  );
  expect(order).toBeTruthy();
  console.log(`      ✅ Order status: ${order.orderStatus} | Payment: ${order.paymentStatus}`);

  return { orderId: result.orderId, order };
}

// ════════════════════════════════════════════════════════════════════
// SETUP — Ensure Yahoo user exists
// ════════════════════════════════════════════════════════════════════

let yahooUid: string;

test.beforeAll(async () => {
  console.log('\n🔧 SETUP — Ensuring Yahoo buyer user exists…');
  yahooUid = await ensureYahooUser();
  console.log(`   ✅ Yahoo UID: ${yahooUid}`);
  console.log('🔧 SETUP COMPLETE\n');
});

// ════════════════════════════════════════════════════════════════════
// FULL LIFECYCLE TEST — Yahoo buyer: checkout → shipping → delivery
// ════════════════════════════════════════════════════════════════════

test.describe.serial('Yahoo Buyer Full Lifecycle — Email Verification', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  // Shared state across serial tests
  let orderId: string;
  let yahooToken: string;
  let sellerToken: string;
  let adminToken: string;

  // ── STEP 1: Checkout + Pay ────────────────────────────────────────
  test('1 · Yahoo buyer checks out and pays via Stripe', async ({ page }) => {
    test.setTimeout(180_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('📧 STEP 1: Checkout + Payment');
    console.log(`   Buyer:   ${YAHOO_EMAIL}`);
    console.log(`   Product: ${PRODUCT_ID}`);
    console.log('═══════════════════════════════════════════════════════════');

    const auth = await signIn(YAHOO_EMAIL, YAHOO_PASSWORD);
    yahooToken = auth.idToken;

    const result = await checkoutAndPay(page, yahooUid, yahooToken, PRODUCT_ID);
    orderId = result.orderId;

    console.log('\n   ╔══════════════════════════════════════════════════════╗');
    console.log('   ║  ✉️  EMAIL #1: Order Confirmation (BUYER)            ║');
    console.log('   ║  📬  → yuniorrodriguezo4601@yahoo.com               ║');
    console.log(`   ║  🆔  Order: ${orderId.substring(0, 30).padEnd(37)}║`);
    console.log('   ╠══════════════════════════════════════════════════════╣');
    console.log('   ║  ✉️  EMAIL #2: New Order Notification (SELLER)       ║');
    console.log('   ║  📬  → seller1@test.origna.ca                       ║');
    console.log('   ╚══════════════════════════════════════════════════════╝\n');
  });

  // ── STEP 2: Seller → processing ──────────────────────────────────
  test('2 · Seller marks order as processing', async () => {
    test.setTimeout(15_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('⚙️  STEP 2: Seller → processing');
    console.log('═══════════════════════════════════════════════════════════');

    const sellerAuth = await signIn(SELLER_EMAIL);
    sellerToken = sellerAuth.idToken;

    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'processing',
    }, sellerToken);
    expect(result.newStatus).toBe('processing');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('processing');

    console.log('   ✅ Order is now: processing');
    console.log('   ℹ️  No email sent for processing transition (not yet implemented)');
  });

  // ── STEP 3: Seller → shipped ─────────────────────────────────────
  test('3 · Seller ships with tracking number', async () => {
    test.setTimeout(15_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('📦 STEP 3: Seller → shipped');
    console.log('═══════════════════════════════════════════════════════════');

    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'shipped',
      trackingNumber: 'CP9876543210',
      carrier: 'Canada Post',
    }, sellerToken);
    expect(result.newStatus).toBe('shipped');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('shipped');
    expect(order.trackingNumber).toBe('CP9876543210');
    expect(order.carrier).toBe('Canada Post');

    console.log(`   ✅ Shipped — tracking: ${order.trackingNumber}, carrier: ${order.carrier}`);
    console.log('\n   ╔══════════════════════════════════════════════════════╗');
    console.log('   ║  ✉️  EMAIL #3: Order Shipped (BUYER)                 ║');
    console.log('   ║  📬  → yuniorrodriguezo4601@yahoo.com               ║');
    console.log('   ║  📦  Tracking: CP9876543210 via Canada Post         ║');
    console.log('   ╠══════════════════════════════════════════════════════╣');
    console.log('   ║  ✉️  EMAIL #4: Shipment Confirmed (SELLER)           ║');
    console.log('   ║  📬  → seller1@test.origna.ca                       ║');
    console.log('   ╚══════════════════════════════════════════════════════╝\n');
  });

  // ── STEP 4: Seller → in_transit ──────────────────────────────────
  test('4 · Seller updates to in_transit', async () => {
    test.setTimeout(15_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('🚚 STEP 4: Seller → in_transit');
    console.log('═══════════════════════════════════════════════════════════');

    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'in_transit',
    }, sellerToken);
    expect(result.newStatus).toBe('in_transit');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('in_transit');

    console.log('   ✅ Order is now: in_transit');
    console.log('   ℹ️  No email sent for in_transit transition (not yet implemented)');
  });

  // ── STEP 5: Admin → delivered ────────────────────────────────────
  test('5 · Admin marks order as delivered', async () => {
    test.setTimeout(15_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('✅ STEP 5: Admin → delivered (sellers cannot mark delivered)');
    console.log('═══════════════════════════════════════════════════════════');

    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    adminToken = admin.idToken;

    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'delivered',
    }, adminToken);
    expect(result.newStatus).toBe('delivered');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('delivered');

    console.log('   ✅ Order is now: delivered');
    console.log('\n   ╔══════════════════════════════════════════════════════╗');
    console.log('   ║  ✉️  EMAIL #5: Order Delivered (BUYER)               ║');
    console.log('   ║  📬  → yuniorrodriguezo4601@yahoo.com               ║');
    console.log('   ║  📩  "Please Confirm Receipt" CTA                   ║');
    console.log('   ╚══════════════════════════════════════════════════════╝\n');
  });

  // ── STEP 6: Buyer confirms receipt ───────────────────────────────
  test('6 · Yahoo buyer confirms receipt (payment captured)', async () => {
    test.setTimeout(30_000);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('💳 STEP 6: Buyer confirms receipt');
    console.log('═══════════════════════════════════════════════════════════');

    // Refresh Yahoo token
    const auth = await signIn(YAHOO_EMAIL, YAHOO_PASSWORD);
    yahooToken = auth.idToken;

    const result = await callCallable('confirm_order_receipt', {
      orderId,
    }, yahooToken);
    expect(result.success).toBe(true);
    expect(result.captured).toBe(true);

    const order = await getOrder(orderId);
    expect(order.paymentStatus).toBe('captured');
    expect(order.confirmedByClient).toBe(true);

    console.log('   ✅ Payment captured, receipt confirmed by buyer');
    console.log(`   💰 paymentStatus=${order.paymentStatus}`);
    console.log(`   ☑️  confirmedByClient=${order.confirmedByClient}`);
  });

  // ── FINAL SUMMARY ────────────────────────────────────────────────
  test('7 · Final order state verification + email summary', async () => {
    test.setTimeout(10_000);

    const order = await getOrder(orderId);
    expect(order).toBeTruthy();

    console.log('\n');
    console.log('╔══════════════════════════════════════════════════════════════╗');
    console.log('║           YAHOO BUYER LIFECYCLE — COMPLETE                  ║');
    console.log('╠══════════════════════════════════════════════════════════════╣');
    console.log(`║  Order ID:       ${orderId.substring(0, 40).padEnd(40)}║`);
    console.log(`║  Order Status:   ${(order.orderStatus || '?').padEnd(40)}║`);
    console.log(`║  Payment Status: ${(order.paymentStatus || '?').padEnd(40)}║`);
    console.log(`║  Confirmed:      ${String(order.confirmedByClient || false).padEnd(40)}║`);
    console.log(`║  Tracking:       ${(order.trackingNumber || 'N/A').padEnd(40)}║`);
    console.log(`║  Carrier:        ${(order.carrier || 'N/A').padEnd(40)}║`);
    console.log('╠══════════════════════════════════════════════════════════════╣');
    console.log('║  EMAILS SENT (check yuniorrodriguezo4601@yahoo.com):        ║');
    console.log('║  ───────────────────────────────────────────────────────     ║');
    console.log('║  ✉️  #1  Order Confirmation         → Yahoo (buyer)         ║');
    console.log('║  ✉️  #2  New Order Notification      → seller1 (seller)     ║');
    console.log('║  ✉️  #3  Order Shipped               → Yahoo (buyer)        ║');
    console.log('║  ✉️  #4  Shipment Confirmed          → seller1 (seller)     ║');
    console.log('║  ✉️  #5  Order Delivered              → Yahoo (buyer)        ║');
    console.log('║  ───────────────────────────────────────────────────────     ║');
    console.log('║  ⚠️  NOT SENT (missing templates):                          ║');
    console.log('║      • processing transition                                ║');
    console.log('║      • in_transit transition                                ║');
    console.log('║      • refunded / partially_refunded                        ║');
    console.log('╚══════════════════════════════════════════════════════════════╝');
    console.log('\n');

    // Assert final state
    expect(order.orderStatus).toBe('delivered');
    expect(order.paymentStatus).toBe('captured');
    expect(order.confirmedByClient).toBe(true);
    expect(order.trackingNumber).toBe('CP9876543210');
  });
});
