/**
 * OrignaGTA — E2E API Helpers (Dev Firebase)
 * ===========================================
 * Targets orignagta-dev deployed environment. No emulators.
 * All Firestore reads use Bearer token auth (no "Bearer owner" emulator trick).
 * No writeDoc/deleteDoc/forceOrderStatus — we cannot directly mutate dev Firestore.
 */

import { Page } from '@playwright/test';

// ════════════════════════════════════════════════════════════════════
// CONFIGURATION — Dev Firebase (hardcoded, no emulator fallback)
// ════════════════════════════════════════════════════════════════════

const FIREBASE_API_KEY = 'REDACTED_SECRET';

export const AUTH_URL = 'https://identitytoolkit.googleapis.com';
export const FIRESTORE_URL = 'https://firestore.googleapis.com';
export const FUNCTIONS_URL = 'https://us-central1-orignagta-dev.cloudfunctions.net';
export const WEB_APP_URL = process.env.E2E_TARGET_URL ?? 'https://orignagta-dev.web.app';
export const PROJECT_ID = 'orignagta-dev';

export const FIRESTORE_BASE = `${FIRESTORE_URL}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

export const DEFAULT_PASS = 'REDACTED_TEST_PASSWORD';

export const STRIPE_CARD = {
  number: '4242424242424242',
  exp: '12/34',
  cvc: '123',
  name: 'Test Buyer',
  postalCode: 'M5V 3A8',
};

// ════════════════════════════════════════════════════════════════════
// TEST ACCOUNTS (Dev Firebase — real accounts)
// ════════════════════════════════════════════════════════════════════

export const TEST_ACCOUNTS = {
  ADMIN_EMAIL: 'yr62813@gmail.com',              // roles: buyer+seller+admin, chargesEnabled, onboardingCompleted
  ADMIN_PASS: 'REDACTED_TEST_PASSWORD',
  SELLER_EMAIL: 'yuniorrodriguezo4601@yahoo.com', // roles: buyer+seller, chargesEnabled
  BUYER_EMAIL: 'yuniorrodriguezo460@gmail.com',   // roles: buyer+admin, NOT a seller-approved account
};

export const TEST_UIDS = {
  ADMIN: 'RU9MI8vYFkQCakMrJfG8iGTuc012',
  SELLER: 'eVxwL5SfEATPnw1zhWYaUdGx8MD2',
  BUYER: 'smy7bq6BXfeTuXKSTZJoOQ9a6K42',
};

// ════════════════════════════════════════════════════════════════════
// FIREBASE AUTH — Sign In via REST API
// ════════════════════════════════════════════════════════════════════

export interface AuthData {
  idToken: string;
  refreshToken: string;
  localId: string;
  email: string;
  [key: string]: any;
}

// Auth token cache — avoids redundant signIn calls that hit Firebase quota
const _authCache = new Map<string, { data: AuthData; expiresAt: number }>();

/**
 * Sign in to Firebase Auth via Identity Toolkit REST API.
 * Caches tokens for 50 minutes (Firebase tokens expire after 60 min).
 */
export async function signIn(email: string, password: string = DEFAULT_PASS): Promise<AuthData> {
  const cacheKey = `${email}:${password}`;
  const cached = _authCache.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt) return cached.data;

  const res = await fetch(
    `${AUTH_URL}/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  const data = await res.json() as any;

  if (!data.idToken) {
    const errMsg = data.error?.message || 'Unknown error';
    throw new Error(`signIn FAILED for ${email}: ${errMsg}`);
  }

  _authCache.set(cacheKey, { data: data as AuthData, expiresAt: Date.now() + 50 * 60_000 });
  return data as AuthData;
}

// ════════════════════════════════════════════════════════════════════
// FIRESTORE REST API — Read-only (no direct writes to dev)
// ════════════════════════════════════════════════════════════════════

/**
 * Read a Firestore document by path (e.g. "orders/abc123").
 * Uses Bearer token for authentication against production Firestore.
 */
export async function readDoc(path: string, token?: string): Promise<any> {
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${FIRESTORE_BASE}/${path}`, { headers });
  if (!res.ok) return null;
  return res.json();
}

/**
 * Read and parse a Firestore document. Returns parsed JS object or null.
 */
export async function getDoc(path: string, token?: string): Promise<any> {
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

/**
 * Write a Firestore document via REST API.
 * Uses PATCH. If updateMask is provided via fields, it does a partial update.
 * If no field selection is needed, it performs a set (create/overwrite).
 */
export async function writeDoc(path: string, fields: Record<string, any>, token?: string, partial = true): Promise<boolean> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  let url = `${FIRESTORE_BASE}/${path}`;
  if (partial) {
    const fieldPaths = Object.keys(fields);
    const queryParams = fieldPaths.map(p => `updateMask.fieldPaths=${p}`).join('&');
    if (queryParams) url += `?${queryParams}`;
  }

  const body = JSON.stringify({ fields });
  if (!token) console.warn('writeDoc called WITHOUT token');
  else console.log(`writeDoc using token length: ${token.length}, prefix: ${token.substring(0, 10)}...`);

  const res = await fetch(url, {
    method: 'PATCH',
    headers,
    body,
  });

  if (!res.ok) {
    const errorBody = await res.text();
    console.error(`writeDoc failed [${res.status}]: ${url}`);
    console.error(`Request Body: ${body}`);
    console.error(`Response Body: ${errorBody}`);
  }

  return res.ok;
}

/**
 * Delete a Firestore document via REST API.
 */
export async function deleteDoc(path: string, token?: string): Promise<boolean> {
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${FIRESTORE_BASE}/${path}`, {
    method: 'DELETE',
    headers,
  });

  return res.ok;
}

// ════════════════════════════════════════════════════════════════════
// FIRESTORE VALUE CONVERSION
// ════════════════════════════════════════════════════════════════════

export function parseVal(v: any): any {
  if (!v) return null;
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return v.doubleValue;
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.nullValue !== undefined) return null;
  if (v.timestampValue) return v.timestampValue;
  if (v.arrayValue) return (v.arrayValue.values || []).map(parseVal);
  if (v.mapValue) {
    const o: Record<string, any> = {};
    for (const [k, val] of Object.entries((v.mapValue.fields || {}) as Record<string, any>)) {
      o[k] = parseVal(val);
    }
    return o;
  }
  return v;
}

export function parseDoc(doc: any): any {
  if (!doc?.fields) return null;
  const r: Record<string, any> = {};
  for (const [k, v] of Object.entries(doc.fields as Record<string, any>)) {
    r[k] = parseVal(v);
  }
  return r;
}

export function toFirestoreFields(obj: Record<string, any>): any {
  const f: Record<string, any> = {};
  for (const [k, v] of Object.entries(obj)) f[k] = toFsVal(v);
  return f;
}

export function toFsVal(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toFsVal) } };
  if (typeof v === 'object') return { mapValue: { fields: toFirestoreFields(v) } };
  return { stringValue: String(v) };
}

// ════════════════════════════════════════════════════════════════════
// FIREBASE FUNCTIONS — Callable Invocation (deployed functions)
// ════════════════════════════════════════════════════════════════════

/**
 * Call a Firebase Callable Function on the deployed dev environment.
 * Returns the raw response body.
 */
export async function callCallable(fn: string, data: any, token: string): Promise<any> {
  const res = await fetch(`${FUNCTIONS_URL}/${fn}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ data }),
  });
  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    // Non-JSON response (e.g. HTML 404 for missing function)
    return { error: { message: `Non-JSON response (${res.status}): ${text.substring(0, 200)}`, status: res.status >= 400 ? 'NOT_FOUND' : 'INTERNAL' } };
  }
}

/**
 * Call a callable function and throw if it returns an error.
 * Auto-retries on rate limit (waits 65s then retries up to 3 times).
 */
export async function callOk(fn: string, data: any, token: string): Promise<any> {
  for (let attempt = 0; attempt < 3; attempt++) {
    const body = await callCallable(fn, data, token);
    if (body.error) {
      const msg = (body.error.message || '').toLowerCase();
      if (msg.includes('rate limit') && attempt < 2) {
        console.log(`⏳ Rate limited on ${fn}, waiting 65s... (attempt ${attempt + 1}/3)`);
        await new Promise(r => setTimeout(r, 65_000));
        continue;
      }
      throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
    }
    return body.result || body;
  }
  throw new Error(`${fn} failed after 3 retries`);
}

/**
 * Checks if an email was sent to the given address by querying _mail_logs via the admin callable function.
 * E2E tests can use this to verify emails without actually sending them via Mailjet.
 */
export async function verifyEmailSent(email: string, adminToken?: string): Promise<any[]> {
  let token = adminToken;
  if (!token) {
    const auth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    token = auth.idToken;
  }
  const res = await callOk('e2e_get_mail_logs', { to: email }, token);
  return res.logs || [];
}

/**
 * Normalize Firebase/gRPC error codes to Firebase SDK style.
 */
function normalizeErrorCode(error: any): { code: string; message: string } {
  const STATUS_TO_CODE: Record<string, string> = {
    'PERMISSION_DENIED': 'permission-denied',
    'FAILED_PRECONDITION': 'failed-precondition',
    'NOT_FOUND': 'not-found',
    'UNAUTHENTICATED': 'unauthenticated',
    'INVALID_ARGUMENT': 'invalid-argument',
    'ALREADY_EXISTS': 'already-exists',
    'RESOURCE_EXHAUSTED': 'resource-exhausted',
    'CANCELLED': 'cancelled',
    'UNAVAILABLE': 'unavailable',
    'INTERNAL': 'internal',
    'DEADLINE_EXCEEDED': 'deadline-exceeded',
    'UNIMPLEMENTED': 'unimplemented',
    'OUT_OF_RANGE': 'out-of-range',
    'DATA_LOSS': 'data-loss',
    'ABORTED': 'aborted',
  };
  const code = error.code || STATUS_TO_CODE[error.status] || error.status?.toLowerCase()?.replace(/_/g, '-') || 'unknown';
  return { code, message: error.message || error.details || '' };
}

/**
 * Call a callable function expecting it to fail.
 * Returns normalized error { code, message }.
 */
export async function callExpectError(fn: string, data: any, token: string): Promise<{ code: string; message: string }> {
  const body = await callCallable(fn, data, token);
  if (body.error) return normalizeErrorCode(body.error);
  if (body.result?.error) return normalizeErrorCode(body.result.error);
  return {
    code: 'unexpected-success',
    message: `Expected ${fn} to fail but it succeeded: ${JSON.stringify(body)}`,
  };
}

// ════════════════════════════════════════════════════════════════════
// CHECKOUT HELPERS — Build payloads from live Firestore data
// ════════════════════════════════════════════════════════════════════

/**
 * Build a valid checkout payload from live Firestore product + buyer data.
 * Reads product and buyer docs to construct the payload.
 */
export async function buildCheckoutPayload(
  buyerUid: string,
  productId: string,
  quantity = 1,
  token?: string
): Promise<{ data: any; product: any; buyer: any }> {
  const prodDoc = await readDoc(`products/${productId}`, token);
  const product = parseDoc(prodDoc);
  if (!product) throw new Error(`Product ${productId} not found in Firestore.`);

  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  const data = {
    userId: buyerUid,
    items: [{
      productId,
      name: product.name,
      price: product.price,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || ['https://picsum.photos/400'],
      isDigital: product.isDigital || false,
    }],
    subtotal: +(product.price * quantity).toFixed(2),
    shippingAddress: {
      street: address.street || '100 King St W',
      apartment: address.apartment || '',
      city: address.city || 'Toronto',
      state: address.state || 'ON',
      postalCode: address.postalCode || 'M5X 1A9',
      country: address.country || 'Canada',
      phoneNumber: address.phoneNumber || '+14165550000',
    },
  };
  return { data, product, buyer };
}

/**
 * Build multi-seller checkout payload.
 */
export async function buildMultiSellerPayload(
  buyerUid: string,
  items: { productId: string; quantity: number }[],
  token?: string
): Promise<any> {
  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  const cartItems: any[] = [];
  let subtotal = 0;
  for (const { productId, quantity } of items) {
    const prodDoc = await readDoc(`products/${productId}`, token);
    const product = parseDoc(prodDoc);
    if (!product) throw new Error(`Product ${productId} not found in Firestore.`);
    cartItems.push({
      productId,
      name: product.name,
      price: product.price,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || ['https://picsum.photos/400'],
      isDigital: product.isDigital || false,
    });
    subtotal += product.price * quantity;
  }

  return {
    userId: buyerUid,
    items: cartItems,
    subtotal: +subtotal.toFixed(2),
    shippingAddress: {
      street: address.street || '100 King St W',
      apartment: address.apartment || '',
      city: address.city || 'Toronto',
      state: address.state || 'ON',
      postalCode: address.postalCode || 'M5X 1A9',
      country: address.country || 'Canada',
      phoneNumber: address.phoneNumber || '+14165550000',
    },
  };
}

// ════════════════════════════════════════════════════════════════════
// ORDER HELPERS — Polling & status checking
// ════════════════════════════════════════════════════════════════════

/**
 * Read and parse an order document. Returns null if not found.
 */
export async function getOrder(orderId: string, token?: string): Promise<any> {
  const doc = await readDoc(`orders/${orderId}`, token);
  return doc ? parseDoc(doc) : null;
}

/**
 * Read product stock quantity. Returns 0 if product not found.
 */
export async function getProductStock(productId: string, token?: string): Promise<number> {
  const doc = await readDoc(`products/${productId}`, token);
  return doc ? (parseDoc(doc)?.stockQuantity ?? 0) : 0;
}

/**
 * Poll until a Firestore doc field matches expected value.
 */
export async function pollDocField(
  path: string,
  field: string,
  expected: any,
  token?: string,
  maxMs = 30_000
): Promise<any> {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const doc = await readDoc(path, token);
    if (doc) {
      const parsed = parseDoc(doc);
      if (parsed?.[field] === expected) return parsed;
    }
    await new Promise(r => setTimeout(r, 2_000));
  }
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

/**
 * Wait for order to reach a target status — polls Firestore.
 */
export async function waitForOrderStatus(
  orderId: string,
  targetStatuses: string[],
  token?: string,
  maxWaitMs = 90_000
): Promise<any> {
  const start = Date.now();
  let lastOrder: any = null;
  while (Date.now() - start < maxWaitMs) {
    const doc = await readDoc(`orders/${orderId}`, token);
    if (doc) {
      const order = parseDoc(doc);
      lastOrder = order;
      if (order && targetStatuses.includes(order.orderStatus)) return order;
    }
    await new Promise(r => setTimeout(r, 3_000));
  }
  const currentStatus = lastOrder?.orderStatus || 'unknown';
  throw new Error(
    `waitForOrderStatus timeout: order ${orderId} expected [${targetStatuses}] but got "${currentStatus}" after ${maxWaitMs}ms`
  );
}

// ════════════════════════════════════════════════════════════════════
// STRIPE CHECKOUT — Page interaction helpers
// ════════════════════════════════════════════════════════════════════

/**
 * Dismiss Stripe modals that may block the checkout form.
 */
export async function dismissStripeModals(page: Page): Promise<void> {
  const linkDismiss = page.locator(
    'button:has-text("Not now"), ' +
    'button:has-text("Pay another way"), ' +
    'button:has-text("Cancel"), ' +
    '[data-testid="link-dismiss"], ' +
    '.LinkModal--close, ' +
    '[aria-label="Close"]'
  ).first();
  if (await linkDismiss.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await linkDismiss.click().catch(() => { });
    await page.waitForTimeout(500);
  }

  // Handle 3DS authentication test iframe
  const threeDSFrame = page.frameLocator('iframe[name*="stripe-challenge"], iframe[name*="__privateStripeFrame"]').first();
  try {
    const completeBtn = threeDSFrame.locator(
      'button:has-text("Complete"), button:has-text("Approve"), #test-source-authorize-3ds'
    ).first();
    if (await completeBtn.isVisible({ timeout: 1_000 }).catch(() => false)) {
      await completeBtn.click().catch(() => { });
      await page.waitForTimeout(1_000);
    }
  } catch {
    // No 3DS frame — expected for 4242 card
  }

  // Dismiss generic overlays
  const overlay = page.locator('.Modal-overlay, .VerificationModal, [data-testid="modal-overlay"]').first();
  if (await overlay.isVisible({ timeout: 500 }).catch(() => false)) {
    await page.keyboard.press('Escape').catch(() => { });
    await page.waitForTimeout(300);
  }
}

/**
 * Fill and submit Stripe Checkout hosted page.
 * Handles email, card number, expiry, CVC, billing, modals, and 3DS.
 */
export async function fillStripeCheckout(
  page: Page,
  email: string,
  card = STRIPE_CARD
): Promise<void> {
  await page.waitForLoadState('networkidle', { timeout: 30_000 }).catch(() => { });
  await dismissStripeModals(page);

  // Fill email if visible
  const emailInput = page.locator('#email, input[name="email"]').first();
  if (await emailInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
    const safeEmail = `test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@origna-test.ca`;
    await emailInput.fill(safeEmail);
    await page.waitForTimeout(1_500);

    // Dismiss Stripe Link SMS verification if it appears
    const smsInput = page.locator('[data-testid="sms-code-input-0"]').first();
    if (await smsInput.isVisible({ timeout: 3_000 }).catch(() => false)) {
      console.log('Stripe Link SMS verification detected — dismissing...');
      const dismissSelectors = [
        'button:has-text("Pay another way")',
        'button:has-text("Not now")',
        'button:has-text("Cancel")',
        '[data-testid="link-dismiss"]',
        '[aria-label="Close"]',
      ];
      for (const sel of dismissSelectors) {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 1_000 }).catch(() => false)) {
          await el.click().catch(() => { });
          await page.waitForTimeout(1_500);
          break;
        }
      }
    }
    await dismissStripeModals(page);
  }

  // Select "Card" payment method if hidden behind accordion
  const cardField = page.locator('#cardNumber, input[name="cardNumber"]').first();
  const cardVisible = await cardField.isVisible({ timeout: 3_000 }).catch(() => false);
  if (!cardVisible) {
    const cardRadio = page.locator('#payment-method-accordion-item-title-card').first();
    if (await cardRadio.isVisible({ timeout: 3_000 }).catch(() => false)) {
      const cardLabel = page.locator('label[for="payment-method-accordion-item-title-card"], #payment-method-accordion-item-title-card').first();
      await cardLabel.click({ force: true }).catch(() => { });
      await page.waitForTimeout(3_000);
    } else {
      const fallbackSelectors = [
        '[data-testid="card-accordion-item-button"]',
        'button:has-text("Card")',
        'button:has-text("Pay with card")',
        '[data-testid="card-tab"]',
        'input[value="card"]',
      ];
      for (const sel of fallbackSelectors) {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 1_500 }).catch(() => false)) {
          await el.click().catch(() => { });
          await page.waitForTimeout(2_000);
          break;
        }
      }
    }
    await dismissStripeModals(page);
  }

  // Wait for card number field
  const cardReady = await cardField.isVisible({ timeout: 20_000 }).catch(() => false);
  if (!cardReady) {
    // Fallback: iframe-based Stripe Elements
    const allFrames = page.frames();
    let foundInFrame = false;
    for (let i = 0; i < allFrames.length; i++) {
      const f = allFrames[i];
      try {
        const cardInput = f.locator('input[name="cardnumber"], input[autocomplete="cc-number"], input[name="number"], input[data-elements-stable-field-name="cardNumber"]').first();
        if (await cardInput.isVisible({ timeout: 2_000 }).catch(() => false)) {
          await cardInput.fill(card.number);
          for (let j = 0; j < allFrames.length; j++) {
            if (j === i) continue;
            const expInput = allFrames[j].locator('input[name="exp-date"], input[autocomplete="cc-exp"]').first();
            if (await expInput.isVisible({ timeout: 1_000 }).catch(() => false)) await expInput.fill(card.exp);
            const cvcInput = allFrames[j].locator('input[name="cvc"], input[autocomplete="cc-csc"]').first();
            if (await cvcInput.isVisible({ timeout: 1_000 }).catch(() => false)) await cvcInput.fill(card.cvc);
          }
          foundInFrame = true;
          return await submitStripePayment(page, card);
        }
      } catch { /* frame not accessible */ }
    }
    if (!foundInFrame) {
      await page.screenshot({ path: '/tmp/stripe-checkout-debug.png', fullPage: true }).catch(() => { });
      throw new Error(`Stripe card field not found. URL: ${page.url()}`);
    }
  } else {
    await cardField.fill(card.number);
  }

  // Fill expiry
  await page.locator('#cardExpiry, input[name="cardExpiry"]').first().fill(card.exp);

  // Fill CVC
  await page.locator('#cardCvc, input[name="cardCvc"]').first().fill(card.cvc);

  // Fill billing name if visible
  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await nameField.fill(card.name);
  }

  // Fill phone number if visible
  const phoneField = page.locator('#phoneNumber, input[name="phoneNumber"]').first();
  if (await phoneField.isVisible({ timeout: 1_000 }).catch(() => false)) {
    await phoneField.fill('+14165550000');
  }

  // Fill postal code if visible
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await postalField.fill(card.postalCode);
  }

  await dismissStripeModals(page);

  // Click Pay and wait for redirect
  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.waitFor({ state: 'visible', timeout: 10_000 });
  await payBtn.click();

  try {
    await page.waitForURL(
      (url: URL) => !url.hostname.includes('checkout.stripe.com'),
      { timeout: 45_000 }
    );
  } catch {
    const errorEl = page.locator('.FieldError, [data-testid="error-message"], .p-Alert, [role="alert"]').first();
    const hasError = await errorEl.isVisible({ timeout: 2_000 }).catch(() => false);
    if (hasError) {
      const text = await errorEl.textContent().catch(() => 'unknown');
      throw new Error(`Stripe payment failed: ${text}`);
    }
    console.log('Still on Stripe Checkout after 45s — payment may still be processing');
  }
}

/** Submit Stripe payment (used after iframe card fill) */
async function submitStripePayment(page: Page, card: typeof STRIPE_CARD): Promise<void> {
  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await nameField.fill(card.name);
  }
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await postalField.fill(card.postalCode);
  }
  await dismissStripeModals(page);
  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.waitFor({ state: 'visible', timeout: 10_000 });
  await payBtn.click();
}

// ════════════════════════════════════════════════════════════════════
// FULL CHECKOUT FLOWS
// ════════════════════════════════════════════════════════════════════

/**
 * Full checkout + pay: create checkout session → navigate to Stripe → fill & submit.
 */
export async function fullCheckoutAndPay(
  page: Page,
  buyerEmail: string,
  productId: string,
  quantity = 1,
  password = DEFAULT_PASS
): Promise<{ orderId: string; checkoutUrl: string }> {
  const auth = await signIn(buyerEmail, password);
  const { data } = await buildCheckoutPayload(auth.localId, productId, quantity, auth.idToken);
  const result = await callOk('create_checkout_session', data, auth.idToken);

  if (!result.orderId) throw new Error('Checkout failed: no orderId returned');
  if (!result.checkoutUrl) throw new Error('Checkout failed: no checkoutUrl returned');

  await page.goto(result.checkoutUrl);
  await fillStripeCheckout(page, buyerEmail);
  await page.waitForTimeout(5_000);

  return { orderId: result.orderId, checkoutUrl: result.checkoutUrl };
}

/**
 * Full multi-seller checkout + pay.
 */
export async function fullMultiSellerCheckoutAndPay(
  page: Page,
  buyerEmail: string,
  items: { productId: string; quantity: number }[],
  password = DEFAULT_PASS
): Promise<{ orderId: string }> {
  const auth = await signIn(buyerEmail, password);
  const payload = await buildMultiSellerPayload(auth.localId, items, auth.idToken);
  const result = await callOk('create_checkout_session', payload, auth.idToken);

  if (!result.orderId) throw new Error('Multi-seller checkout failed: no orderId');

  await page.goto(result.checkoutUrl);
  await fillStripeCheckout(page, buyerEmail);
  await page.waitForTimeout(5_000);

  return { orderId: result.orderId };
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT DISCOVERY — Dev Firestore has auto-generated product IDs
// ════════════════════════════════════════════════════════════════════

interface DiscoveredProduct {
  id: string;
  name: string;
  price: number;
  sellerId: string;
  stockQuantity: number;
  lifecycleStatus: string;
}

let _cachedProducts: DiscoveredProduct[] | null = null;

/** Clear the product cache so the next call re-fetches from Firestore. */
export function invalidateProductCache(): void {
  _cachedProducts = null;
}

/**
 * Stable product IDs used across E2E test runs.
 * Using fixed IDs + getDoc (single-document GET) avoids runQuery (list) permission
 * issues — Firestore rules evaluate `resource.data` reliably for individual GETs.
 */
const STABLE_TEST_PRODUCTS: Array<{ id: string; sellerUid: string; prefix: string }> = [
  { id: 'e2e_product_admin_seller',  sellerUid: TEST_UIDS.ADMIN,  prefix: 'A' },
  { id: 'e2e_product_test_seller',   sellerUid: TEST_UIDS.SELLER, prefix: 'B' },
];

/**
 * Discover available products in dev Firestore.
 * Uses stable product IDs + individual getDoc calls instead of runQuery to avoid
 * Firestore list-operation permission issues. Creates products if they don't exist.
 * Results are cached for the test run (call invalidateProductCache() to refresh).
 */
export async function discoverProducts(_token?: string): Promise<DiscoveredProduct[]> {
  if (_cachedProducts) return _cachedProducts;

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const products: DiscoveredProduct[] = [];

  for (const { id, sellerUid, prefix } of STABLE_TEST_PRODUCTS) {
    let product: DiscoveredProduct | null = null;
    try {
      const fields = await getDoc(`products/${id}`, adminAuth.idToken);
      if (fields && fields.lifecycleStatus === 'active' && (fields.stockQuantity ?? 0) > 0) {
        product = {
          id,
          name: fields.name || `E2E Product ${prefix}`,
          price: fields.price || 0,
          sellerId: fields.sellerId || sellerUid,
          stockQuantity: fields.stockQuantity,
          lifecycleStatus: 'active',
        };
      }
    } catch { /* will create below */ }

    if (!product) {
      product = await createDummyProduct(sellerUid, prefix, id);
    }
    products.push(product);
  }

  _cachedProducts = products;
  return _cachedProducts;
}

/**
 * Get a single test product with live stock check.
 * Prefers products with highest stock. The buyer must NOT be the seller.
 */
export async function getTestProduct(token: string, excludeSellerId?: string): Promise<DiscoveredProduct> {
  const products = await discoverProducts(token);
  const candidates = excludeSellerId
    ? products.filter(p => p.sellerId !== excludeSellerId)
    : products;

  if (candidates.length === 0) {
    throw new Error('No purchasable products found (after excluding seller).');
  }

  // Re-check stock for top candidates (cache may be stale)
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  for (const product of candidates.slice(0, 5)) {
    try {
      const doc = await readDoc(`products/${product.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        product.stockQuantity = live.stockQuantity; // update cache
        return product;
      }
    } catch { /* skip, try next */ }
  }

  // Fallback: invalidate cache and re-discover
  invalidateProductCache();
  const fresh = await discoverProducts(token);
  const freshCandidates = excludeSellerId
    ? fresh.filter(p => p.sellerId !== excludeSellerId)
    : fresh;

  if (freshCandidates.length === 0) {
    throw new Error('All products are out of stock. Restock dev Firestore.');
  }
  return freshCandidates[0];
}

/**
 * Get two products from different sellers (for multi-seller tests).
 * Returns null if only one seller has products with stock.
 */
export async function getTwoSellerProducts(token: string): Promise<[DiscoveredProduct, DiscoveredProduct] | null> {
  const products = await discoverProducts(token);
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const sellers = new Map<string, DiscoveredProduct>();

  for (const p of products) {
    if (sellers.has(p.sellerId)) continue;
    // Live stock check
    try {
      const doc = await readDoc(`products/${p.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        p.stockQuantity = live.stockQuantity;
        sellers.set(p.sellerId, p);
      }
    } catch { /* skip */ }
    if (sellers.size >= 2) break;
  }

  if (sellers.size < 2) return null;
  const [a, b] = [...sellers.values()];
  return [a, b];
}

export async function createDummyProduct(sellerUid: string, prefix: string, productId?: string): Promise<DiscoveredProduct> {
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const id = productId ?? `test_dummy_${prefix}_${Date.now()}`;
  const productData = {
    sellerId: sellerUid,
    sellerSku: `DUMMY-${prefix}-${Date.now()}`,
    name: `Dummy Test Product ${prefix}`,
    description: `A high-quality test product created for E2E testing purposes.`,
    price: 15.99,
    lifecycleStatus: 'active',
    stockQuantity: 100,
    categoryId: 1,
    imageUrls: ['https://orignagta-dev.web.app/assets/icons/icon-192.png'],
    keywords: ['dummy', prefix],
    rating: 0,
    createdAt: new Date(),
    sellerAddress: {
      street: '100 University Ave',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5J 1V6',
      country: 'Canada'
    }
  };

  const ok = await writeDoc(`products/${id}`, toFirestoreFields(productData), adminAuth.idToken, false);
  if (!ok) throw new Error(`Failed to create dummy product for ${sellerUid}`);

  return {
    id,
    name: productData.name,
    price: productData.price,
    sellerId: productData.sellerId,
    stockQuantity: productData.stockQuantity,
    lifecycleStatus: productData.lifecycleStatus,
  };
}

/**
 * Ensures two products from different sellers exist on the dev environment.
 * Delegates to discoverProducts which creates stable products if missing.
 */
export async function ensureTwoSellerProducts(_token: string): Promise<[DiscoveredProduct, DiscoveredProduct]> {
  const products = await discoverProducts();
  const adminProd = products.find(p => p.sellerId === TEST_UIDS.ADMIN);
  const sellerProd = products.find(p => p.sellerId === TEST_UIDS.SELLER);
  if (!adminProd || !sellerProd) {
    // Stale cache — invalidate and retry once
    invalidateProductCache();
    const fresh = await discoverProducts();
    const a = fresh.find(p => p.sellerId === TEST_UIDS.ADMIN);
    const b = fresh.find(p => p.sellerId === TEST_UIDS.SELLER);
    if (!a || !b) throw new Error('ensureTwoSellerProducts: failed to ensure products for both sellers');
    return [a, b];
  }
  return [adminProd, sellerProd];
}

// ════════════════════════════════════════════════════════════════════
// SELLER AUTH — Map known seller UIDs to test accounts
// ════════════════════════════════════════════════════════════════════

const SELLER_UID_TO_EMAIL: Record<string, string> = {
  [TEST_UIDS.ADMIN]: TEST_ACCOUNTS.ADMIN_EMAIL,
  [TEST_UIDS.SELLER]: TEST_ACCOUNTS.SELLER_EMAIL,
};

/**
 * Sign in as the seller who owns a product (by sellerId).
 * In dev, all products are owned by the admin account.
 */
export async function getSellerAuth(sellerId: string): Promise<AuthData> {
  const email = SELLER_UID_TO_EMAIL[sellerId];
  if (!email) throw new Error(`Unknown seller UID: ${sellerId}. Add mapping to SELLER_UID_TO_EMAIL.`);
  return signIn(email);
}

// ════════════════════════════════════════════════════════════════════
// CONVENIENCE
// ════════════════════════════════════════════════════════════════════

export function uid(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT MANIPULATION
// ════════════════════════════════════════════════════════════════════

/**
 * Programmatically updates the trending status of a product.
 * Used to set up E2E tests for trending products.
 */
export async function setProductTrending(productId: string, isTrending: boolean, adminToken?: string): Promise<boolean> {
  const token = adminToken ?? (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS)).idToken;
  const docData = await getDoc(`products/${productId}`, token);
  if (!docData) throw new Error(`Product ${productId} not found`);

  const updates: Record<string, any> = {
    isTrending: isTrending,
    trendingAt: isTrending ? new Date() : null
  };

  return writeDoc(`products/${productId}`, toFirestoreFields(updates), token, true);
}
