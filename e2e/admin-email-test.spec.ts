// @ts-check
/**
 * OrignaGTA — Real Email Verification E2E Tests
 * ===============================================
 * Three purchase tests that send REAL Mailjet emails to
 * yr62813@gmail.com (Gmail) and yuniorrodriguezo4601@yahoo.com (Yahoo).
 *
 *   Test 1 → Gmail   buys  → BUYER  email  → Gmail inbox  ✉️
 *   Test 2 → Yahoo   buys  → BUYER  email  → Yahoo inbox  ✉️
 *   Test 3 → Gmail   buys from Yahoo seller → SELLER email → Yahoo inbox  ✉️
 *
 * Prerequisites:
 *   1. firebase emulators:start
 *   2. cd e2e && npx ts-node mega-seed.ts
 *   3. stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
 *   4. FORCE_REAL_EMAIL=true must be in functions/.env
 *   5. npx playwright test admin-email-test.spec.ts --reporter=list
 */
import { test, expect } from '@playwright/test';

// ════════════════════════════════════════════════════════════════════
// CONFIG
// ════════════════════════════════════════════════════════════════════

const AUTH_EMULATOR   = 'http://localhost:9099';
const FIRESTORE_EMU   = 'http://localhost:8080';
const FUNCTIONS_EMU   = 'http://localhost:5001';
const PROJECT_ID      = 'orignagta';

// Infrastructure availability cache
let infraAvailable: {
  auth: boolean | null;
  firestore: boolean | null;
  functions: boolean | null;
} = {
  auth: null,
  firestore: null,
  functions: null,
};

/** Check if infrastructure is available */
async function checkInfrastructure(request: any): Promise<typeof infraAvailable> {
  if (infraAvailable.auth === null) {
    const [authRes, firestoreRes, functionsRes] = await Promise.all([
      request.get(`${AUTH_EMULATOR}/`).catch(() => null),
      request.get(`${FIRESTORE_EMU}/`).catch(() => null),
      request.get(`${FUNCTIONS_EMU}/`).catch(() => null),
    ]);
    infraAvailable = {
      auth: !!authRes,
      firestore: !!firestoreRes,
      functions: !!functionsRes,
    };
    if (Object.values(infraAvailable).some(v => !v)) {
      console.log('⚠️  Some infrastructure is unavailable:');
      console.log(`   Auth: ${infraAvailable.auth ? '✅' : '❌'}`);
      console.log(`   Firestore: ${infraAvailable.firestore ? '✅' : '❌'}`);
      console.log(`   Functions: ${infraAvailable.functions ? '✅' : '❌'}`);
    }
  }
  return infraAvailable;
}

const GMAIL_EMAIL    = 'yr62813@gmail.com';
const GMAIL_PASSWORD = '960227Y#y';

const YAHOO_EMAIL    = 'yuniorrodriguezo4601@yahoo.com';
const YAHOO_PASSWORD = 'TestYahoo123!';

const STRIPE_CARD = {
  number: '4242424242424242', exp: '12/30', cvc: '123',
  name: 'Test Buyer', postalCode: 'M5V 3A8',
};

// ════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════

function toFirestoreFields(obj: any): any {
  const f: any = {};
  for (const [k, v] of Object.entries(obj)) f[k] = toFsVal(v);
  return f;
}
function toFsVal(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toFsVal) } };
  if (typeof v === 'object') return { mapValue: { fields: toFirestoreFields(v) } };
  return { stringValue: String(v) };
}

/** Create a user in the Auth emulator and return the UID */
async function createAuthUser(email: string, password: string, displayName: string): Promise<string> {
  const res = await fetch(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, displayName, returnSecureToken: true }) }
  );
  const data = await res.json();
  if (data.error) {
    // User already exists — just sign in instead
    if (data.error.message?.includes('EMAIL_EXISTS')) {
      const signInRes = await signIn(email, password);
      return signInRes.localId;
    }
    throw new Error(`createAuthUser: ${data.error.message}`);
  }
  const uid = data.localId;
  // Mark email verified
  await fetch(`${AUTH_EMULATOR}/emulator/v1/projects/${PROJECT_ID}/accounts`, {
    method: 'PATCH', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ localId: uid, emailVerified: true }),
  });
  return uid;
}

/** Write / merge a Firestore document */
async function writeDoc(path: string, data: any): Promise<boolean> {
  const fields = toFirestoreFields(data);
  const fieldPaths = Object.keys(data).map(k => `updateMask.fieldPaths=${k}`).join('&');
  const res = await fetch(
    `${FIRESTORE_EMU}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}?${fieldPaths}`,
    { method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
      body: JSON.stringify({ fields }) }
  );
  return res.ok;
}

async function signIn(email: string, password: string) {
  const res = await fetch(
    `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }) }
  );
  const data = await res.json();
  if (data.error) throw new Error(`Sign-in failed: ${data.error.message}`);
  // Force email verified
  if (data.idToken) {
    const upd = await fetch(
      `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:update?key=fake-api-key`,
      { method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken: data.idToken, emailVerified: true, returnSecureToken: true }) }
    );
    const u = await upd.json();
    if (u.idToken) { data.idToken = u.idToken; data.refreshToken = u.refreshToken || data.refreshToken; }
  }
  return data;
}

async function callCallable(fn: string, payload: any, token: string) {
  const res = await fetch(`${FUNCTIONS_EMU}/${PROJECT_ID}/us-central1/${fn}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ data: payload }),
  });
  const body = await res.json();
  if (body.error) throw new Error(`${fn}: ${body.error.message || JSON.stringify(body.error)}`);
  return body.result || body;
}

async function readDoc(path: string) {
  const res = await fetch(
    `${FIRESTORE_EMU}/v1/projects/${PROJECT_ID}/databases/(default)/documents/${path}`,
    { headers: { Authorization: 'Bearer owner' } }
  );
  if (!res.ok) return null;
  return res.json();
}

function parseVal(v: any): any {
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return v.doubleValue;
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.nullValue !== undefined) return null;
  if (v.timestampValue) return v.timestampValue;
  if (v.arrayValue) return (v.arrayValue.values || []).map(parseVal);
  if (v.mapValue) {
    const o: any = {};
    for (const [k, val] of Object.entries(v.mapValue.fields || {})) o[k] = parseVal(val);
    return o;
  }
  return v;
}

function parseDoc(doc: any): any {
  if (!doc?.fields) return null;
  const r: any = {};
  for (const [k, v] of Object.entries(doc.fields)) r[k] = parseVal(v);
  return r;
}

async function waitForOrderStatus(
  orderId: string, targetStatuses: string[], maxWaitMs = 45_000
): Promise<any> {
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const doc = await readDoc(`orders/${orderId}`);
    if (doc) {
      const order = parseDoc(doc);
      if (targetStatuses.includes(order.orderStatus)) return order;
    }
    await new Promise(r => setTimeout(r, 2_000));
  }
  const doc = await readDoc(`orders/${orderId}`);
  return doc ? parseDoc(doc) : null;
}

/** Reusable: checkout + pay on Stripe + wait for webhook confirmation */
async function fullCheckoutAndPay(
  page: any, buyerEmail: string, buyerUid: string, buyerToken: string,
  productId: string, cardName: string
): Promise<{ orderId: string; order: any; product: any }> {
  // Read product
  const prodDoc = await readDoc(`products/${productId}`);
  const product = parseDoc(prodDoc);
  expect(product).toBeTruthy();

  // Read buyer
  const buyerDoc = await readDoc(`users/${buyerUid}`);
  const buyer = parseDoc(buyerDoc);
  expect(buyer).toBeTruthy();
  const address = buyer?.address || {};

  // Build payload
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
      street: address.street || '100 King St W',
      apartment: address.apartment || '',
      city: address.city || 'Toronto',
      state: address.state || 'ON',
      postalCode: address.postalCode || 'M5X 1A9',
      country: address.country || 'CA',
      phoneNumber: address.phoneNumber || '+14165550000',
    },
  };

  // Create checkout
  console.log('   💳 Creating checkout session…');
  const result = await callCallable('create_checkout_session', payload, buyerToken);
  expect(result.orderId).toBeTruthy();
  expect(result.checkoutUrl).toBeTruthy();
  console.log(`      ✅ Order: ${result.orderId}`);

  // Navigate to Stripe & pay
  console.log('   💰 Paying via Stripe Checkout…');
  await page.goto(result.checkoutUrl);
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => {});

  const emailInput = page.locator('#email, input[name="email"]').first();
  if (await emailInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await emailInput.fill(buyerEmail);
    await page.waitForTimeout(500);
  }
  const cardField = page.locator('#cardNumber, input[name="cardNumber"]').first();
  await cardField.waitFor({ state: 'visible', timeout: 15_000 });
  await cardField.fill(STRIPE_CARD.number);
  await page.locator('#cardExpiry, input[name="cardExpiry"]').first().fill(STRIPE_CARD.exp);
  await page.locator('#cardCvc, input[name="cardCvc"]').first().fill(STRIPE_CARD.cvc);
  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false))
    await nameField.fill(cardName);
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false))
    await postalField.fill(STRIPE_CARD.postalCode);

  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.click();
  console.log('      ⏳ Payment submitted — waiting for webhook…');
  await page.waitForTimeout(8_000);

  // Wait for confirmation
  const order = await waitForOrderStatus(
    result.orderId,
    ['confirmed', 'processing', 'payment_authorized'],
    45_000
  );
  expect(order).toBeTruthy();
  console.log(`      ✅ Order status: ${order.orderStatus} | Payment: ${order.paymentStatus}`);

  return { orderId: result.orderId, order, product };
}

// ════════════════════════════════════════════════════════════════════
// SETUP — Create Yahoo user + Yahoo seller product (once)
// ════════════════════════════════════════════════════════════════════

let yahooUid: string;
const YAHOO_PRODUCT_ID = 'product_yahoo_001';

test.beforeAll(async () => {
  console.log('\n🔧 SETUP — Creating Yahoo user as buyer+seller…');

  // 1. Create Yahoo user in Auth
  yahooUid = await createAuthUser(YAHOO_EMAIL, YAHOO_PASSWORD, 'Yunior Yahoo');
  console.log(`   ✅ Yahoo Auth UID: ${yahooUid}`);

  // 2. Create Yahoo user document in Firestore (buyer + seller)
  await writeDoc(`users/${yahooUid}`, {
    email: YAHOO_EMAIL,
    displayName: 'Yunior Yahoo',
    roles: ['buyer', 'seller'],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    suspended: false,
    // Top-level onboarding fields (checked by create_checkout_session)
    onboardingCompleted: true,
    chargesEnabled: true,
    payoutsEnabled: true,
    stripeAccountId: 'acct_test_yahoo_001',
    address: {
      street: '350 Rue Saint-Paul',
      apartment: 'Suite 200',
      city: 'Montreal',
      state: 'QC',
      postalCode: 'H2Y 1H2',
      country: 'Canada',
      phoneNumber: '+15141234567',
      isDefault: true,
      label: 'Home',
      latitude: 45.5088,
      longitude: -73.554,
    },
    sellerProfile: {
      businessName: "Yunior's Montreal Boutique",
      businessAddress: {
        street: '350 Rue Saint-Paul',
        apartment: 'Suite 200',
        city: 'Montreal',
        state: 'QC',
        postalCode: 'H2Y 1H2',
        country: 'Canada',
        phoneNumber: '+15141234567',
      },
      stripeAccountId: 'acct_test_yahoo_001',
      payoutsEnabled: true,
      chargesEnabled: true,
      onboardingCompleted: true,
    },
  });
  console.log('   ✅ Yahoo Firestore user created (buyer + onboarded seller)');

  // 3. Create a product owned by Yahoo seller
  await writeDoc(`products/${YAHOO_PRODUCT_ID}`, {
    name: 'Handcrafted Montreal Candle Set',
    description: 'Set of 3 soy candles with Quebec maple, cedar & lavender scents. Hand-poured in Old Montreal.',
    price: 42.99,
    categoryId: 3,
    sellerId: yahooUid,
    sellerName: 'Yunior Yahoo',
    stockQuantity: 50,
    status: 'active',
    approved: true,
    featured: false,
    imageUrls: ['https://picsum.photos/seed/candle/400/400'],
    keywords: ['candle', 'soy', 'montreal', 'handmade'],
    freeShipping: false,
    isDigital: false,
    isLocalDeliveryOnly: false,
    isPerishable: false,
    estimatedShipDays: 3,
    weightKg: 0.8,
    deliveryOptions: [
      { speed: 'standard', isEnabled: true, estimatedDays: 5, price: 0 },
      { speed: 'express', isEnabled: true, estimatedDays: 2, price: 8.99 },
    ],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  });
  console.log('   ✅ Yahoo seller product created: Handcrafted Montreal Candle Set ($42.99)');
  console.log('🔧 SETUP COMPLETE\n');
});

// ════════════════════════════════════════════════════════════════════
// TEST 1 — Gmail BUYER email (admin buys from seller1)
// ════════════════════════════════════════════════════════════════════

test.describe.serial('Real Email Verification', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('1 · Gmail BUYER email — Admin buys Quebec Scarf → yr62813@gmail.com', async ({ page }) => {
    console.log('═══════════════════════════════════════════════════');
    console.log('📧 TEST 1: BUYER confirmation → Gmail');
    console.log('═══════════════════════════════════════════════════');

    const auth = await signIn(GMAIL_EMAIL, GMAIL_PASSWORD);
    console.log(`   🔐 Admin signed in — UID: ${auth.localId}`);

    const { orderId, product } = await fullCheckoutAndPay(
      page, GMAIL_EMAIL, auth.localId, auth.idToken,
      'product_001', // Handmade Quebec Scarf ($45.99, seller1 QC)
      'Admin Yunior'
    );

    console.log('\n   ╔══════════════════════════════════════════════╗');
    console.log('   ║  ✉️  CHECK GMAIL: yr62813@gmail.com          ║');
    console.log('   ║  📩  BUYER order confirmation email          ║');
    console.log(`   ║  📦  ${product.name.padEnd(35)}║`);
    console.log(`   ║  🆔  Order: ${orderId.substring(0, 20).padEnd(29)}║`);
    console.log('   ╚══════════════════════════════════════════════╝\n');
  });

  // ════════════════════════════════════════════════════════════════════
  // TEST 2 — Yahoo BUYER email (Yahoo user buys from seller3)
  // ════════════════════════════════════════════════════════════════════

  test('2 · Yahoo BUYER email — Yahoo buys Beef Jerky → yuniorrodriguezo4601@yahoo.com', async ({ page }) => {
    console.log('═══════════════════════════════════════════════════');
    console.log('📧 TEST 2: BUYER confirmation → Yahoo');
    console.log('═══════════════════════════════════════════════════');

    const auth = await signIn(YAHOO_EMAIL, YAHOO_PASSWORD);
    console.log(`   🔐 Yahoo signed in — UID: ${auth.localId}`);

    const { orderId, product } = await fullCheckoutAndPay(
      page, YAHOO_EMAIL, auth.localId, auth.idToken,
      'product_007', // Alberta Beef Jerky Gift Box ($34.99, seller3 AB)
      'Yunior Yahoo'
    );

    console.log('\n   ╔══════════════════════════════════════════════════════╗');
    console.log('   ║  ✉️  CHECK YAHOO: yuniorrodriguezo4601@yahoo.com     ║');
    console.log('   ║  📩  BUYER order confirmation email                  ║');
    console.log(`   ║  📦  ${product.name.padEnd(43)}║`);
    console.log(`   ║  🆔  Order: ${orderId.substring(0, 20).padEnd(37)}║`);
    console.log('   ╚══════════════════════════════════════════════════════╝\n');
  });

  // ════════════════════════════════════════════════════════════════════
  // TEST 3 — Yahoo SELLER email (Admin buys from Yahoo seller's store)
  //          → Buyer email goes to Gmail, SELLER email goes to Yahoo
  // ════════════════════════════════════════════════════════════════════

  test('3 · Yahoo SELLER email — Admin buys Yahoo\'s Candle Set → seller notification to Yahoo', async ({ page }) => {
    console.log('═══════════════════════════════════════════════════');
    console.log('📧 TEST 3: SELLER notification → Yahoo');
    console.log('═══════════════════════════════════════════════════');

    const auth = await signIn(GMAIL_EMAIL, GMAIL_PASSWORD);
    console.log(`   🔐 Admin signed in — UID: ${auth.localId}`);

    const { orderId, product } = await fullCheckoutAndPay(
      page, GMAIL_EMAIL, auth.localId, auth.idToken,
      YAHOO_PRODUCT_ID, // Handcrafted Montreal Candle Set ($42.99, Yahoo seller)
      'Admin Yunior'
    );

    console.log('\n   ╔══════════════════════════════════════════════════════════════╗');
    console.log('   ║  ✉️  CHECK YAHOO: yuniorrodriguezo4601@yahoo.com              ║');
    console.log('   ║  📩  SELLER notification — "New Order Received"              ║');
    console.log('   ║  💰  Someone bought your product!                            ║');
    console.log(`   ║  📦  ${product.name.padEnd(51)}║`);
    console.log(`   ║  🆔  Order: ${orderId.substring(0, 20).padEnd(45)}║`);
    console.log('   ╠══════════════════════════════════════════════════════════════╣');
    console.log('   ║  ALSO CHECK GMAIL: yr62813@gmail.com                        ║');
    console.log('   ║  📩  BUYER order confirmation (admin bought the candle set) ║');
    console.log('   ╚══════════════════════════════════════════════════════════════╝\n');
  });
});
