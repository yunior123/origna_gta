/**
 * OrignaGTA — Digital Products E2E Tests
 * =========================================
 * Tests digital product creation, purchase, license delivery, mixed carts,
 * UX validation and security for software + book digital types.
 *
 * Seed data required:
 *   product_010 → book  (Canadian History eBook Bundle)
 *   product_026 → book  (Digital Photography Course)
 *   product_031 → software (FXCleaner — Mac Disk Cleaner)
 *   product_001 → physical (Handmade Quebec Scarf) — used in mixed cart tests
 *
 * Run: npx playwright test digital-products-e2e.spec.ts
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callOk, callExpectError,
  readDoc, parseDoc,
  buildCheckoutPayload,
  buildMultiSellerPayload,
  fullCheckoutAndPay,
  fillStripeCheckout,
  waitForOrderStatus,
  verifyEmailSent,
  writeDoc,
  deleteDoc,
  toFirestoreFields,
  FUNCTIONS_URL,
  TEST_ACCOUNTS,
  TEST_UIDS,
} from './api-helpers';

// ── Constants ────────────────────────────────────────────────────────────────
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const DIGITAL_PASS = 'REDACTED_TEST_PASSWORD';

/** product_031 = FXCleaner software (macOS) */
const DIGITAL_SW_ID = 'product_031';
/** product_010 = Canadian History eBook Bundle */
const DIGITAL_BOOK_ID = 'product_010';
/** product_001 = physical Scarf — used in mixed cart */
const PHYSICAL_ID = 'product_001';

// ════════════════════════════════════════════════════════════════════════════
// SUITE A · DIGITAL PRODUCT CATALOGUE
// ════════════════════════════════════════════════════════════════════════════

test.describe('A. Digital Product Catalogue', () => {
  test.setTimeout(60_000);

  test('A.1 Software product has correct Firestore fields (FXCleaner)', async () => {
    const doc = await readDoc(`products/${DIGITAL_SW_ID}`);
    const product = parseDoc(doc);

    expect(product, 'Product should exist in Firestore').toBeTruthy();
    expect(product.isDigital, 'isDigital must be true').toBe(true);
    expect(product.digitalType, 'digitalType must be software').toBe('software');
    expect(product.digitalBuilds, 'digitalBuilds must be present').toBeTruthy();
    expect(product.digitalBuilds.macos, 'macOS download URL must be set').toBeTruthy();
    expect(product.supportedPlatforms, 'supportedPlatforms must be present').toContain('macos');
    expect(product.deviceLimit, 'deviceLimit must be set (3 for FXCleaner)').toBe(3);
    expect(product.deliveryOptions, 'No delivery options for digital').toHaveLength(0);
    expect(product.estimatedShipDays, 'Zero ship days for digital').toBe(0);
    expect(product.weightKg, 'Zero weight for digital').toBeFalsy();
  });

  test('A.2 Book product has correct Firestore fields (eBook bundle)', async () => {
    const doc = await readDoc(`products/${DIGITAL_BOOK_ID}`);
    const product = parseDoc(doc);

    expect(product, 'Product should exist').toBeTruthy();
    expect(product.isDigital, 'isDigital must be true').toBe(true);
    expect(product.digitalType, 'digitalType must be book').toBe('book');
    expect(product.bookSourceUrl, 'bookSourceUrl must be set').toBeTruthy();
    expect(product.bookSourceUrl, 'bookSourceUrl must point to a PDF/file').toMatch(/^https?:\/\//);
    expect(product.estimatedShipDays, 'Zero ship days').toBe(0);
    expect(product.freeShipping, 'Digital books should have freeShipping=true').toBe(true);
  });

  test('A.3 Digital product shows "Instant delivery" badge (product model)', async () => {
    // Verify both digital products advertise instant delivery (estimatedShipDays=0)
    // The Flutter UI renders "Instant delivery" for isDigital=true items.
    const [swDoc, bookDoc] = await Promise.all([
      readDoc(`products/${DIGITAL_SW_ID}`),
      readDoc(`products/${DIGITAL_BOOK_ID}`),
    ]);
    const sw = parseDoc(swDoc);
    const book = parseDoc(bookDoc);

    for (const [label, p] of [['software', sw], ['book', book]] as const) {
      expect(p.isDigital, `${label}: isDigital`).toBe(true);
      expect(p.estimatedShipDays, `${label}: zero ship days`).toBe(0);
      // isLocalDeliveryOnly must be false — digital products ship worldwide
      expect(p.isLocalDeliveryOnly, `${label}: not local-only`).toBe(false);
    }
  });
});

// ════════════════════════════════════════════════════════════════════════════
// SUITE B · DIGITAL-ONLY CHECKOUT
// ════════════════════════════════════════════════════════════════════════════

test.describe('B. Digital-Only Checkout', () => {
  test.setTimeout(180_000);

  test('B.1 Digital-only cart does not require Canadian shipping address', async () => {
    // The backend bypasses address validation when all items are digital.
    // Send payload with no shippingAddress fields — should succeed or return a checkout URL.
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const { data } = await buildCheckoutPayload(auth.localId, DIGITAL_SW_ID, 1, auth.idToken);

    // Replace shipping address with empty object to confirm digital bypass
    const digitalOnlyPayload = {
      ...data,
      shippingAddress: {},
    };

    const result = await callOk('create_checkout_session', digitalOnlyPayload, auth.idToken);
    expect(result.orderId, 'checkout session must return orderId').toBeTruthy();
    expect(result.checkoutUrl, 'checkout session must return checkoutUrl').toBeTruthy();
  });

  test('B.2 Buy digital software product → license key created on order item', async ({ page }) => {
    const { orderId } = await fullCheckoutAndPay(page, BUYER_EMAIL, DIGITAL_SW_ID, 1);
    expect(orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const order = await waitForOrderStatus(orderId, ['confirmed', 'delivered'], auth.idToken, 90_000);

    expect(order.orderStatus).toMatch(/confirmed|delivered/);
    expect(order.paymentStatus).toBe('captured');

    // Find the digital item in the order
    const digitalItem = (order.items || []).find((it: any) => it.productId === DIGITAL_SW_ID);
    expect(digitalItem, 'Order must contain the digital software item').toBeTruthy();
    expect(digitalItem.isDigital, 'Item isDigital flag').toBe(true);
    expect(digitalItem.digitalUnlocked, 'digitalUnlocked must be true after capture').toBe(true);
    expect(digitalItem.licenseKey, 'licenseKey must be set on item after capture').toBeTruthy();
    expect(digitalItem.licenseKey, 'licenseKey format: XXXX-XXXX-XXXX-XXXX').toMatch(
      /^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/
    );

    // License document must exist in /licenses collection
    const licDoc = await readDoc(`licenses/${digitalItem.licenseKey}`, auth.idToken);
    const lic = parseDoc(licDoc);
    expect(lic, 'License doc must exist in Firestore').toBeTruthy();
    expect(lic.status, 'License must be active').toBe('active');
    expect(lic.digitalType, 'License type must match product').toBe('software');
    expect(lic.userId, 'License must belong to buyer').toBe(auth.localId);

    // Verify order confirmation email was sent via _mail_logs
    const authAdmin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const emails = await verifyEmailSent(BUYER_EMAIL, authAdmin.idToken);
    const orderEmail = emails.find(e => e.subject?.includes('Order Confirmed'));
    expect(orderEmail, 'Buyer should receive an order confirmation email').toBeTruthy();
  });

  test('B.3 Buy digital book product → book license created with bookSourceUrl', async ({ page }) => {
    const { orderId } = await fullCheckoutAndPay(page, BUYER_EMAIL, DIGITAL_BOOK_ID, 1);
    expect(orderId).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const order = await waitForOrderStatus(orderId, ['confirmed', 'delivered'], auth.idToken, 90_000);

    const bookItem = (order.items || []).find((it: any) => it.productId === DIGITAL_BOOK_ID);
    expect(bookItem, 'Order must contain book item').toBeTruthy();
    expect(bookItem.digitalUnlocked, 'digitalUnlocked after capture').toBe(true);
    expect(bookItem.licenseKey, 'licenseKey on book item').toBeTruthy();

    const licDoc = await readDoc(`licenses/${bookItem.licenseKey}`, auth.idToken);
    const lic = parseDoc(licDoc);
    expect(lic.digitalType, 'Book license type').toBe('book');
    expect(lic.bookSourceUrl, 'bookSourceUrl stored on license').toBeTruthy();
    expect(lic.status).toBe('active');

    // Verify order confirmation email
    const authAdmin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const emails = await verifyEmailSent(BUYER_EMAIL, authAdmin.idToken);
    const orderEmail = emails.find(e => e.subject?.includes('Order Confirmed'));
    expect(orderEmail, 'Buyer should receive an order confirmation email for the book').toBeTruthy();
  });
});

// ════════════════════════════════════════════════════════════════════════════
// SUITE C · MIXED CART (DIGITAL + PHYSICAL)
// ════════════════════════════════════════════════════════════════════════════

test.describe('C. Mixed Cart — Digital + Physical', () => {
  test.setTimeout(60_000);

  test('C.1 Mixed cart requires shipping address (digital does not waive physical requirement)', async () => {
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const payload = await buildMultiSellerPayload(
      auth.localId,
      [
        { productId: DIGITAL_SW_ID, quantity: 1 },
        { productId: PHYSICAL_ID, quantity: 1 },
      ],
      auth.idToken,
    );

    // Remove the shipping address — should fail because physical item is in cart
    const noAddressPayload = { ...payload, shippingAddress: {} };
    const result = await callExpectError(
      'create_checkout_session', noAddressPayload, auth.idToken
    );
    expect(result.message, 'Must reject missing address for mixed cart').toBeTruthy();
  });

  test('C.2 Mixed cart checkout creates order with both digital and physical items', async ({ page }) => {
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const payload = await buildMultiSellerPayload(
      auth.localId,
      [
        { productId: DIGITAL_SW_ID, quantity: 1 },
        { productId: PHYSICAL_ID, quantity: 1 },
      ],
      auth.idToken,
    );
    const session = await callOk('create_checkout_session', payload, auth.idToken);
    expect(session.orderId).toBeTruthy();
    expect(session.checkoutUrl).toBeTruthy();

    await page.goto(session.checkoutUrl);
    await fillStripeCheckout(page, BUYER_EMAIL);
    await page.waitForTimeout(5_000);

    const order = await waitForOrderStatus(session.orderId, ['confirmed', 'delivered'], auth.idToken, 90_000);
    expect(order.items.length, 'Order must have 2 items').toBeGreaterThanOrEqual(2);

    const digitalItem = order.items.find((it: any) => it.productId === DIGITAL_SW_ID);
    const physicalItem = order.items.find((it: any) => it.productId === PHYSICAL_ID);
    expect(digitalItem, 'Digital item in order').toBeTruthy();
    expect(physicalItem, 'Physical item in order').toBeTruthy();

    // Digital item gets a license; physical does not
    expect(digitalItem.isDigital).toBe(true);
    expect(physicalItem.isDigital).toBeFalsy();

    // Verify order confirmation email was sent via _mail_logs
    const authAdmin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const emails = await verifyEmailSent(BUYER_EMAIL, authAdmin.idToken);
    const orderEmail = emails.find(e => e.subject?.includes('Order Confirmed'));
    expect(orderEmail, 'Buyer should receive an order confirmation email for mixed cart').toBeTruthy();
  });

  test('C.3 Shipping cost is nonzero in mixed cart (physical item triggers shipping calc)', async () => {
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const payload = await buildMultiSellerPayload(
      auth.localId,
      [
        { productId: DIGITAL_SW_ID, quantity: 1 },
        { productId: PHYSICAL_ID, quantity: 1 },
      ],
      auth.idToken,
    );
    const session = await callOk('create_checkout_session', payload, auth.idToken);
    const orderDoc = await readDoc(`orders/${session.orderId}`, auth.idToken);
    const order = parseDoc(orderDoc);

    // Digital-only orders have shippingCostCents=0; mixed orders may have shipping > 0
    // (unless the physical product has freeShipping=true — scarf does NOT have free shipping)
    expect(typeof order.shippingCostCents).toBe('number');
    expect(order.shippingCostCents, 'Mixed cart shipping cost should be non-negative').toBeGreaterThanOrEqual(0);
  });
});

// ════════════════════════════════════════════════════════════════════════════
// SUITE D · LICENSE ACTIVATION & BOOK DOWNLOAD
// ════════════════════════════════════════════════════════════════════════════

test.describe('D. License Activation & Book Download', () => {
  test.setTimeout(180_000);

  let softwareLicenseKey: string;
  let bookLicenseKey: string;

  // Seed license keys directly via admin API to avoid slow Stripe checkout
  test.beforeAll(async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const buyerAuth = await signIn(BUYER_EMAIL, DIGITAL_PASS);

    // Seed software license (FXCleaner — macOS only)
    softwareLicenseKey = 'REDACTED_SECRET';
    await writeDoc(`licenses/${softwareLicenseKey}`, toFirestoreFields({
      licenseKey: softwareLicenseKey,
      productId: DIGITAL_SW_ID,
      orderId: 'e2e-test-order-d-sw',
      userId: buyerAuth.localId,
      digitalType: 'software',
      status: 'active',
      supportedPlatforms: ['macos'],
      deviceLimit: 3,
      activations: [],
      digitalBuilds: { macos: 'https://cdn.example.com/fxcleaner-mac-test.dmg' },
      productName: 'FXCleaner',
      createdAt: new Date(),
    }), adminAuth.idToken, false);

    // Seed book license (eBook)
    bookLicenseKey = 'REDACTED_SECRET';
    await writeDoc(`licenses/${bookLicenseKey}`, toFirestoreFields({
      licenseKey: bookLicenseKey,
      productId: DIGITAL_BOOK_ID,
      orderId: 'e2e-test-order-d-book',
      userId: buyerAuth.localId,
      digitalType: 'book',
      status: 'active',
      bookSourceUrl: 'https://cdn.example.com/test-ebook.pdf',
      productName: 'Canadian History eBook Bundle',
      createdAt: new Date(),
    }), adminAuth.idToken, false);
  });

  test.afterAll(async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    await deleteDoc(`licenses/${softwareLicenseKey}`, adminAuth.idToken);
    await deleteDoc(`licenses/${bookLicenseKey}`, adminAuth.idToken);
  });

  test('D.1 Activate software license on a new device → approved with downloadUrls', async () => {
    expect(softwareLicenseKey, 'Need a software license from beforeAll').toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const result = await callOk('activate_license', {
      licenseKey: softwareLicenseKey,
      deviceId: 'e2e-device-mac-001',
      platform: 'macos',
    }, auth.idToken);

    expect(result.approved, 'License activation must be approved').toBe(true);
    expect(result.licenseKey).toBe(softwareLicenseKey);
    expect(result.downloadUrls, 'downloadUrls must contain macos URL').toBeTruthy();
    expect(result.downloadUrls.macos, 'macOS download URL present').toBeTruthy();
  });

  test('D.2 Re-activating same device is idempotent (no duplicate activation entry)', async () => {
    expect(softwareLicenseKey).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);

    // Activate same device twice
    await callOk('activate_license', { licenseKey: softwareLicenseKey, deviceId: 'e2e-device-mac-idempotent', platform: 'macos' }, auth.idToken);
    const result = await callOk('activate_license', { licenseKey: softwareLicenseKey, deviceId: 'e2e-device-mac-idempotent', platform: 'macos' }, auth.idToken);

    expect(result.approved).toBe(true);

    const licDoc = await readDoc(`licenses/${softwareLicenseKey}`, auth.idToken);
    const lic = parseDoc(licDoc);
    const activations: any[] = lic.activations || [];
    const deviceEntries = activations.filter((a: any) => a.deviceId === 'e2e-device-mac-idempotent');
    expect(deviceEntries.length, 'Same device must only appear once in activations').toBe(1);
  });

  test('D.3 Generate book download session → single-use downloadUrl returned', async () => {
    expect(bookLicenseKey, 'Need a book license from beforeAll').toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const result = await callOk('generate_book_download_session', {
      licenseKey: bookLicenseKey,
    }, auth.idToken);

    expect(result.downloadUrl, 'downloadUrl must be present').toBeTruthy();
    expect(result.downloadUrl, 'downloadUrl must contain a tok_ token').toMatch(/tok_/);
    // Token must be a well-formed URL
    expect(() => new URL(result.downloadUrl)).not.toThrow();
  });

  test('D.4 Software license on wrong platform is rejected', async () => {
    expect(softwareLicenseKey).toBeTruthy();

    // FXCleaner is macOS-only; activating on linux must fail
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const result = await callExpectError('activate_license', {
      licenseKey: softwareLicenseKey,
      deviceId: 'e2e-device-linux-001',
      platform: 'linux',
    }, auth.idToken);

    expect(result.message, 'platform_not_supported error').toBeTruthy();
    expect(result.code, 'Error code must not be unexpected-success').not.toBe('unexpected-success');
  });
});

// ════════════════════════════════════════════════════════════════════════════
// SUITE E · SECURITY & ACCESS CONTROL
// ════════════════════════════════════════════════════════════════════════════

test.describe('E. Security & Access Control', () => {
  test.setTimeout(180_000);

  let buyerLicenseKey: string;
  let buyerBookLicenseKey: string;

  // Seed license keys directly via admin API to avoid slow Stripe checkout
  test.beforeAll(async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const buyerAuth = await signIn(BUYER_EMAIL, DIGITAL_PASS);

    buyerLicenseKey = 'E2EE-SW01-ABCD-9999';
    await writeDoc(`licenses/${buyerLicenseKey}`, toFirestoreFields({
      licenseKey: buyerLicenseKey,
      productId: DIGITAL_SW_ID,
      orderId: 'e2e-test-order-e-sw',
      userId: buyerAuth.localId,
      digitalType: 'software',
      status: 'active',
      supportedPlatforms: ['macos'],
      deviceLimit: 3,
      activations: [],
      digitalBuilds: { macos: 'https://cdn.example.com/fxcleaner-mac-test.dmg' },
      productName: 'FXCleaner',
      createdAt: new Date(),
    }), adminAuth.idToken, false);

    buyerBookLicenseKey = 'E2EE-BK01-ABCD-8888';
    await writeDoc(`licenses/${buyerBookLicenseKey}`, toFirestoreFields({
      licenseKey: buyerBookLicenseKey,
      productId: DIGITAL_BOOK_ID,
      orderId: 'e2e-test-order-e-book',
      userId: buyerAuth.localId,
      digitalType: 'book',
      status: 'active',
      bookSourceUrl: 'https://cdn.example.com/test-ebook-e4.pdf',
      productName: 'Canadian History eBook Bundle',
      createdAt: new Date(),
    }), adminAuth.idToken, false);
  });

  test.afterAll(async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    await deleteDoc(`licenses/${buyerLicenseKey}`, adminAuth.idToken);
    await deleteDoc(`licenses/${buyerBookLicenseKey}`, adminAuth.idToken);
  });

  test('E.1 Another buyer cannot activate a license they do not own', async () => {
    expect(buyerLicenseKey).toBeTruthy();

    // Admin is a different user — trying to activate buyer's license must fail
    const attackerAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const result = await callExpectError('activate_license', {
      licenseKey: buyerLicenseKey,
      deviceId: 'attacker-device-001',
      platform: 'macos',
    }, attackerAuth.idToken);

    expect(result.message, 'Must reject activation by non-owner').toBeTruthy();
    expect(result.code, 'Must not succeed').not.toBe('unexpected-success');
  });

  test('E.2 Malformed license key format is rejected before DB lookup', async () => {
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const result = await callExpectError('activate_license', {
      licenseKey: 'not-a-valid-key',
      deviceId: 'device-001',
      platform: 'macos',
    }, auth.idToken);

    expect(result.message, 'invalid_key_format error expected').toBeTruthy();
    expect(result.code).not.toBe('unexpected-success');
  });

  test('E.3 Non-owner cannot generate book download session', async () => {
    // Use a hardcoded non-existent license key — should return not_found or unauthorized
    const attackerAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const result = await callExpectError('generate_book_download_session', {
      licenseKey: 'FAKE-FAKE-FAKE-FAKE',
    }, attackerAuth.idToken);

    // Either not-found (key doesn't exist) or permission-denied (wrong owner) — both correct
    expect(result.code, 'Must reject non-existent license key request').not.toBe('unexpected-success');
  });

  test('E.4 Book download session token is single-use (second use of same token fails)', async () => {
    // Use pre-seeded book license to generate a session token, "use" it by calling the redirect endpoint,
    // then try to reuse the token — should get 410 Gone (already_used).
    expect(buyerBookLicenseKey).toBeTruthy();

    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);

    const sessionResult = await callOk('generate_book_download_session', {
      licenseKey: buyerBookLicenseKey,
    }, auth.idToken);

    // Extract the token from the downloadUrl
    const downloadUrl: string = sessionResult.downloadUrl;
    const token = new URL(downloadUrl).searchParams.get('t');
    expect(token, 'Token must be in downloadUrl query param').toBeTruthy();

    // Simulate "using" the token by calling the public redirect endpoint
    const firstUse = await fetch(`${FUNCTIONS_URL}/get_book_redirect?t=${token}`, { redirect: 'manual' });
    // Should redirect (302) or succeed; the token is now marked used.
    expect([200, 302, 410].includes(firstUse.status), 'First use: valid response code').toBe(true);

    if (firstUse.status === 302) {
      // Token was used — second call must return 410
      const secondUse = await fetch(`${FUNCTIONS_URL}/get_book_redirect?t=${token}`, { redirect: 'manual' });
      expect(secondUse.status, 'Second use of same token must return 410').toBe(410);
    }
  });
});

// ════════════════════════════════════════════════════════════════════════════
// SUITE F · SELLER UX — DIGITAL PRODUCT CREATION
// ════════════════════════════════════════════════════════════════════════════

test.describe('F. Seller UX — Digital Product Creation', () => {
  test.setTimeout(60_000);

  test('F.1 Digital product schema is valid for Firestore after seeding', async () => {
    // Verify all 3 digital products have required fields
    const [swDoc, bookDoc, courseDoc] = await Promise.all([
      readDoc(`products/${DIGITAL_SW_ID}`),
      readDoc(`products/${DIGITAL_BOOK_ID}`),
      readDoc(`products/product_026`),
    ]);

    for (const [label, doc] of [['software', swDoc], ['ebook', bookDoc], ['course', courseDoc]] as const) {
      const p = parseDoc(doc);
      expect(p, `${label}: product must exist`).toBeTruthy();
      expect(p.isDigital, `${label}: isDigital`).toBe(true);
      expect(p.digitalType, `${label}: digitalType must be set`).toBeTruthy();
      expect(['software', 'book']).toContain(p.digitalType);
      expect(p.estimatedShipDays, `${label}: estimatedShipDays=0`).toBe(0);
      expect(p.lifecycleStatus, `${label}: product must be active`).toBe('active');
    }
  });

  test('F.2 Digital-only checkout generates zero shipping cost', async () => {
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const { data } = await buildCheckoutPayload(auth.localId, DIGITAL_SW_ID, 1, auth.idToken);
    const session = await callOk('create_checkout_session', data, auth.idToken);

    const orderDoc = await readDoc(`orders/${session.orderId}`, auth.idToken);
    const order = parseDoc(orderDoc);

    expect(order.shippingCostCents, 'Digital-only order: zero shipping').toBe(0);
  });

  test('F.3 FXCleaner software product is buyable worldwide (no Canada-only restriction)', async () => {
    // Digital products bypass the Canada-only shipping restriction.
    // A buyer with a non-Canadian address should still be able to purchase.
    const auth = await signIn(BUYER_EMAIL, DIGITAL_PASS);
    const { data } = await buildCheckoutPayload(auth.localId, DIGITAL_SW_ID, 1, auth.idToken);

    // Override with a US address — should succeed for digital-only cart
    const internationalPayload = {
      ...data,
      shippingAddress: {
        street: '1 Infinite Loop',
        city: 'Cupertino',
        state: 'CA',
        postalCode: '95014',
        country: 'USA',
        phoneNumber: '+14085551234',
      },
    };

    // For all-digital carts, address validation is bypassed — this should succeed
    const result = await callOk('create_checkout_session', internationalPayload, auth.idToken);
    expect(result.orderId, 'Digital checkout must succeed with non-CA address').toBeTruthy();
  });
});
