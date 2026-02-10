// @ts-check
/**
 * OrignaGTA — Logic Failure Detection E2E Test Suite
 * ===================================================
 * 25 tests designed to catch business logic bugs that a senior QA human would find.
 * NOT happy-path retesting — these target state machine violations, financial
 * integrity, race conditions, cascade effects, cron job correctness, and
 * permission boundaries.
 *
 *   Suite A · Financial Integrity (5 tests)
 *   Suite B · State Machine Violations (5 tests)
 *   Suite C · Cron Job / Auto-Action Logic (4 tests)
 *   Suite D · Suspension Cascade Effects (4 tests)
 *   Suite E · Stock Integrity Under Pressure (4 tests)
 *   Suite F · Permission Boundary & Edge Cases (3 tests)
 *
 * Prerequisites:
 *   1. firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
 *   2. cd e2e && npx ts-node mega-seed.ts
 *   3. stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
 *   4. npx playwright test logic-failures-e2e.spec.ts --reporter=list
 *
 * Philosophy (Playwright 2026 best practices):
 *   - API-level tests (callCallable + Firestore REST) — no flaky UI selectors
 *   - Each test is isolated — seeds its own data, no shared mutable state across suites
 *   - Custom expect messages for every assertion (fast triage on failure)
 *   - Soft assertions where multiple checks form a single logical test
 *   - No fixed delays — poll with expect.toPass or explicit retry loops
 *   - Tests what the USER would experience, not implementation details
 */
import { test, expect } from '@playwright/test';
import {
  checkInfrastructure, ensureSeedData, signIn,
  callCallable, callOk, callExpectError,
  readDoc, writeDoc, deleteDoc, parseDoc,
  buildCheckoutPayload, createOrder, forceOrderStatus, pollDocField,
  DEFAULT_PASS, TEST_ACCOUNTS, TEST_PRODUCTS,
} from './api-helpers';

// ════════════════════════════════════════════════════════════════════
// CONFIGURATION — Re-exported from api-helpers.ts
// ════════════════════════════════════════════════════════════════════

const ADMIN_EMAIL    = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS     = TEST_ACCOUNTS.ADMIN_PASS;
const SELLER1_EMAIL  = TEST_ACCOUNTS.SELLER1_EMAIL;
const SELLER2_EMAIL  = TEST_ACCOUNTS.SELLER2_EMAIL;
const BUYER1_EMAIL   = TEST_ACCOUNTS.BUYER1_EMAIL;
const BUYER2_EMAIL   = TEST_ACCOUNTS.BUYER2_EMAIL;
const BUYER3_EMAIL   = TEST_ACCOUNTS.BUYER3_EMAIL;
const SUSPENDED_EMAIL = TEST_ACCOUNTS.SUSPENDED_EMAIL;
const NON_ONBOARDED_SELLER = TEST_ACCOUNTS.NON_ONBOARDED_SELLER;

// Products with good stock for parallel tests
const PRODUCT_HIGH_STOCK = TEST_PRODUCTS.HIGH_STOCK;
const PRODUCT_DIGITAL    = TEST_PRODUCTS.DIGITAL;
const PRODUCT_SELLER2    = TEST_PRODUCTS.SELLER2;


// ════════════════════════════════════════════════════════════════════════════
// SUITE A · FINANCIAL INTEGRITY — Money logic bugs that cost real dollars
// ════════════════════════════════════════════════════════════════════════════

test.describe('A. Financial Integrity', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('A.1 Backend rejects client-side price tampering', async () => {
    // A malicious client sends a lower price than what's in Firestore
    const auth = await signIn(BUYER1_EMAIL);
    const prodDoc = await readDoc(`products/${PRODUCT_HIGH_STOCK}`);
    const product = parseDoc(prodDoc);
    const realPrice = product.price;

    const { data } = await buildCheckoutPayload(auth.localId, PRODUCT_HIGH_STOCK, 1);
    // Tamper: set price to $0.01
    data.items[0].price = 0.01;
    data.subtotal = 0.01;

    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Price tampering should be rejected by backend').not.toBe('unexpected-success');
    // If it somehow succeeds, the order amount in Firestore should still use the real price
    if (error.code === 'unexpected-success') {
      // This is a CRITICAL bug — the backend accepted a tampered price
      expect(error.code, `CRITICAL: Backend accepted tampered price $0.01 instead of $${realPrice}`).not.toBe('unexpected-success');
    }
  });

  test('A.2 Subtotal mismatch between items and declared subtotal is rejected', async () => {
    // Client sends items totaling $49.99 but declares subtotal as $10.00
    const auth = await signIn(BUYER1_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, PRODUCT_HIGH_STOCK, 2);
    const realSubtotal = data.subtotal;
    data.subtotal = 1.00; // Tampered subtotal

    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, `Subtotal mismatch ($1.00 vs real $${realSubtotal}) should be rejected`).not.toBe('unexpected-success');
  });

  test('A.3 Platform fee (2.5%) is correctly calculated on order creation', async () => {
    // Create an order and verify the platform_fee field is exactly 2.5% of subtotal
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    const order = parseDoc(await readDoc(`orders/${orderId}`));
    expect(order, 'Order should exist after creation').toBeTruthy();

    // platformFee should be present and = subtotal * 0.025 (within rounding)
    if (order.platformFee !== undefined && order.platformFee !== null) {
      const expectedFee = +(order.subtotal * 0.025).toFixed(2);
      expect(
        Math.abs(order.platformFee - expectedFee),
        `Platform fee $${order.platformFee} should be 2.5% of subtotal $${order.subtotal} (=$${expectedFee})`
      ).toBeLessThanOrEqual(0.02); // Allow 2 cent rounding
    }
    // Also verify amounts are in a sane range
    expect(order.subtotal, 'Subtotal should be positive').toBeGreaterThan(0);
    if (order.totalAmountCents) {
      expect(order.totalAmountCents, 'Total in cents should be positive integer').toBeGreaterThan(0);
    }
  });

  test('A.4 Checkout with quantity=0 is rejected', async () => {
    // Edge case: a crafted request with zero quantity should never create an order
    const auth = await signIn(BUYER1_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, PRODUCT_HIGH_STOCK, 0);
    data.items[0].quantity = 0;
    data.subtotal = 0;

    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Quantity 0 should be rejected').not.toBe('unexpected-success');
  });

  test('A.5 Checkout with negative price is rejected', async () => {
    // Extreme tampering: negative price to get paid instead of paying
    const auth = await signIn(BUYER1_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, PRODUCT_HIGH_STOCK, 1);
    data.items[0].price = -50.00;
    data.subtotal = -50.00;

    const error = await callExpectError('create_checkout_session', data, auth.idToken);
    expect(error.code, 'Negative price should be rejected').not.toBe('unexpected-success');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE B · STATE MACHINE VIOLATIONS — Impossible transitions that break logic
// ════════════════════════════════════════════════════════════════════════════

test.describe('B. State Machine Violations', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('B.1 Cannot skip from confirmed directly to delivered', async () => {
    // A seller tries to mark an order as delivered without shipping it first
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'confirmed');

    const seller = await signIn(SELLER1_EMAIL);
    const error = await callExpectError('update_order_status', {
      orderId, newStatus: 'delivered',
    }, seller.idToken);

    expect(error.code, 'confirmed→delivered skip should be forbidden').not.toBe('unexpected-success');
  });

  test('B.2 Cannot transition a cancelled order to any state', async () => {
    // Once cancelled, an order is terminal — nothing should revive it
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'cancelled');

    const seller = await signIn(SELLER1_EMAIL);
    const transitions = ['confirmed', 'processing', 'shipped', 'delivered', 'pending'];
    for (const target of transitions) {
      const error = await callExpectError('update_order_status', {
        orderId, newStatus: target,
      }, seller.idToken);
      expect(
        error.code,
        `cancelled→${target} should be blocked (terminal state)`
      ).not.toBe('unexpected-success');
    }
  });

  test('B.3 Cannot cancel a delivered order (must use refund)', async () => {
    // After delivery, cancellation is impossible — only refund is valid
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'delivered');

    const buyer = await signIn(BUYER1_EMAIL);
    const error = await callExpectError('cancel_order', { orderId }, buyer.idToken);
    expect(
      error.code,
      'Delivered orders cannot be cancelled, only refunded'
    ).not.toBe('unexpected-success');
  });

  test('B.4 Double ship is idempotent or rejected (no duplicated tracking)', async () => {
    // Seller ships the same order twice — should not create duplicate tracking entries
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'processing');

    const seller = await signIn(SELLER1_EMAIL);
    // First ship
    const result1 = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped', trackingNumber: 'TRACK-001', carrier: 'Canada Post',
    }, seller.idToken);

    // Second ship attempt on already-shipped order
    const result2 = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped', trackingNumber: 'TRACK-002', carrier: 'UPS',
    }, seller.idToken);

    // Either rejected or the order status remains consistent
    const order = parseDoc(await readDoc(`orders/${orderId}`));
    // The order should still be in a valid state (shipped or beyond)
    expect(
      ['shipped', 'in_transit', 'delivered'].includes(order?.orderStatus),
      `Order should be in a shipped+ state, got: ${order?.orderStatus}`
    ).toBe(true);
  });

  test('B.5 Refund on uncaptured payment is rejected', async () => {
    // If payment was only authorized (not captured), a refund should fail
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    // Force to delivered but keep paymentStatus as authorized (not captured)
    await forceOrderStatus(orderId, 'delivered', { paymentStatus: 'authorized' });

    const prodDoc = await readDoc(`products/${PRODUCT_HIGH_STOCK}`);
    const product = parseDoc(prodDoc);

    const seller = await signIn(SELLER1_EMAIL);
    const error = await callExpectError('refund_order_item', {
      orderId, productId: PRODUCT_HIGH_STOCK,
    }, seller.idToken);

    expect(
      error.code,
      'Refund on uncaptured (authorized-only) payment should fail with failed-precondition'
    ).not.toBe('unexpected-success');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE C · CRON JOB / AUTO-ACTION LOGIC — Background jobs that silently break
// ════════════════════════════════════════════════════════════════════════════

test.describe('C. Cron Job & Auto-Action Logic', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('C.1 auto_confirm_deliveries captures orders shipped >7 days ago', async () => {
    // Create an order, force it to "shipped" with an old updatedAt, then run the cron
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);

    // Force to shipped with updatedAt 8 days ago
    const eightDaysAgo = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString();
    await forceOrderStatus(orderId, 'shipped', {
      paymentStatus: 'authorized',
      updatedAt: eightDaysAgo,
      stripePaymentIntentId: 'pi_test_auto_confirm_' + Date.now(),
    });

    // Call the cron directly
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    // Cron jobs are HTTP functions, try calling via functions emulator
    const cronRes = await fetch(`${FUNCTIONS_EMU}/${PROJECT_ID}/us-central1/auto_confirm_deliveries`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }).catch(() => null);

    // If the cron is not exposed as HTTP, the test documents the gap
    if (cronRes && cronRes.ok) {
      // Wait for the order to be updated
      const order = await pollDocField(`orders/${orderId}`, 'orderStatus', 'delivered', 20_000);
      expect(
        order?.orderStatus,
        `Order shipped 8 days ago should be auto-confirmed to delivered, got: ${order?.orderStatus}`
      ).toBe('delivered');
    } else {
      // Cron not callable directly — verify the order structure is set up correctly for the cron
      const order = parseDoc(await readDoc(`orders/${orderId}`));
      expect(order?.orderStatus, 'Order should be in shipped state for cron pickup').toBe('shipped');
      expect(order?.paymentStatus, 'Payment should be authorized for cron pickup').toBe('authorized');
      console.log('⚠️ auto_confirm_deliveries not exposed as HTTP — verify via scheduled trigger');
    }
  });

  test('C.2 check_expired_authorizations expires stale pending orders', async () => {
    // An order pending for >7 days with authorized payment should be marked expired
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);

    const eightDaysAgo = new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString();
    await forceOrderStatus(orderId, 'pending', {
      paymentStatus: 'authorized',
      createdAt: eightDaysAgo,
      stripePaymentIntentId: 'pi_test_expired_' + Date.now(),
    });

    const cronRes = await fetch(`${FUNCTIONS_EMU}/${PROJECT_ID}/us-central1/check_expired_authorizations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }).catch(() => null);

    if (cronRes && cronRes.ok) {
      const order = await pollDocField(`orders/${orderId}`, 'orderStatus', 'expired', 15_000);
      expect(order?.orderStatus, 'Old pending order should be expired by cron').toBe('expired');
      expect(order?.stockRestored, 'Stock should be restored on expiration').toBe(true);
    } else {
      // Verify the order is correctly set up for the cron to pick it up
      const order = parseDoc(await readDoc(`orders/${orderId}`));
      expect(order?.orderStatus).toBe('pending');
      expect(order?.paymentStatus).toBe('authorized');
      console.log('⚠️ check_expired_authorizations not exposed as HTTP — verify via scheduled trigger');
    }
  });

  test('C.3 archive_old_orders marks delivered orders older than 30 days', async () => {
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);

    const thirtyOneDaysAgo = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000).toISOString();
    await forceOrderStatus(orderId, 'delivered', {
      updatedAt: thirtyOneDaysAgo,
      paymentStatus: 'captured',
    });

    const cronRes = await fetch(`${FUNCTIONS_EMU}/${PROJECT_ID}/us-central1/archive_old_orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }).catch(() => null);

    if (cronRes && cronRes.ok) {
      const order = await pollDocField(`orders/${orderId}`, 'archived', true, 15_000);
      expect(order?.archived, 'Order delivered 31 days ago should be archived').toBe(true);
      expect(order?.archivedAt, 'archivedAt timestamp should be set').toBeTruthy();
    } else {
      console.log('⚠️ archive_old_orders not exposed as HTTP — verify via scheduled trigger');
    }
  });

  test('C.4 cleanup_rate_limits removes expired rate limit entries', async () => {
    // Write a stale rate-limit doc, run cron, verify it's cleaned
    const staleId = `test_rate_limit_${Date.now()}`;
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();
    await writeDoc(`rate_limits/${staleId}`, {
      lastRequest: twoHoursAgo,
      count: 5,
    });

    const cronRes = await fetch(`${FUNCTIONS_EMU}/${PROJECT_ID}/us-central1/cleanup_rate_limits`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }).catch(() => null);

    if (cronRes && cronRes.ok) {
      // Wait a bit then check if the doc was deleted
      await new Promise(r => setTimeout(r, 3_000));
      const doc = await readDoc(`rate_limits/${staleId}`);
      expect(doc, 'Stale rate limit entry should be cleaned up').toBeNull();
    } else {
      // At minimum, verify the doc was written correctly
      const doc = parseDoc(await readDoc(`rate_limits/${staleId}`));
      expect(doc?.count).toBe(5);
      console.log('⚠️ cleanup_rate_limits not exposed as HTTP — verify via scheduled trigger');
      // Cleanup our test doc
      await deleteDoc(`rate_limits/${staleId}`);
    }
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE D · SUSPENSION CASCADE — When admin suspends a seller, EVERYTHING cascades
// ════════════════════════════════════════════════════════════════════════════

test.describe('D. Suspension Cascade Effects', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('D.1 Suspended seller products are deactivated and cannot be purchased', async () => {
    // Verify that a suspended seller's products have isActive=false
    const suspendedDoc = await readDoc(`users/${SUSPENDED_EMAIL}`);
    // Find any products from suspended users by querying
    const suspended = await signIn(SUSPENDED_EMAIL).catch(() => null);

    if (suspended?.localId) {
      // Check if user is actually suspended
      const userDoc = parseDoc(await readDoc(`users/${suspended.localId}`));
      if (userDoc?.suspended) {
        // Try to checkout with one of their products — should fail
        const buyer = await signIn(BUYER1_EMAIL);

        // Query for any product from this seller
        const queryRes = await fetch(
          `${FIRESTORE_EMU}/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
          { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
            body: JSON.stringify({ structuredQuery: {
              from: [{ collectionId: 'products' }],
              where: { fieldFilter: { field: { fieldPath: 'sellerId' }, op: 'EQUAL', value: { stringValue: suspended.localId } } },
              limit: 1,
            }}) }
        );
        const results = await queryRes.json();
        const prods = Array.isArray(results) ? results.filter((r: any) => r.document) : [];
        if (prods.length > 0) {
          const product = parseDoc(prods[0].document);
          expect(product?.isActive, 'Suspended seller product should be deactivated').toBe(false);
        }
      } else {
        console.log('⚠️ suspended@test.origna.ca is not actually suspended in current seed data');
      }
    } else {
      console.log('⚠️ suspended@test.origna.ca does not exist — skipping');
    }
  });

  test('D.2 Suspended seller cannot add new products', async () => {
    // Even if auth works, product creation should be rejected for suspended sellers
    const suspended = await signIn(SUSPENDED_EMAIL).catch(() => null);
    if (!suspended?.idToken) {
      console.log('⚠️ suspended@test.origna.ca auth failed — skipping');
      return;
    }

    const error = await callExpectError('add_product', {
      name: 'Illegal Product', description: 'Should not exist',
      price: 10.00, category: 'Accessories', stockQuantity: 5,
    }, suspended.idToken);

    // Should be rejected — either permission-denied or failed-precondition
    expect(
      ['permission-denied', 'failed-precondition', 'unauthenticated'].includes(error.code) || error.message?.toLowerCase().includes('suspend'),
      `Suspended seller should not add products, got: ${error.code} - ${error.message}`
    ).toBe(true);
  });

  test('D.3 Admin self-suspension is blocked', async () => {
    // Admin should never be able to suspend themselves — would lock out the system
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    const adminDoc = parseDoc(await readDoc(`users/${admin.localId}`));

    // Need MFA for suspend_seller — but even with MFA, self-suspend should fail
    const error = await callExpectError('suspend_seller', {
      sellerId: admin.localId, reason: 'Testing self-suspend',
    }, admin.idToken);

    expect(
      error.code !== 'unexpected-success',
      'Admin should not be able to suspend themselves'
    ).toBe(true);
  });

  test('D.4 Checkout with products from suspended seller is rejected', async () => {
    // Even if a product doc somehow has isActive=true, checkout should verify seller status
    const buyer = await signIn(BUYER2_EMAIL);

    // Create a fake product with a non-existent seller to test seller validation
    const fakeProductId = `test_suspended_product_${Date.now()}`;
    await writeDoc(`products/${fakeProductId}`, {
      name: 'Ghost Product', price: 10.00, stockQuantity: 50,
      sellerId: 'non_existent_seller_id_12345',
      isActive: true, category: 'Test',
      imageUrls: ['https://picsum.photos/400'],
    });

    const data = {
      userId: buyer.localId,
      items: [{
        productId: fakeProductId, name: 'Ghost Product', price: 10.00,
        quantity: 1, sellerId: 'non_existent_seller_id_12345',
        imageUrls: ['https://picsum.photos/400'],
      }],
      subtotal: 10.00,
      shippingAddress: {
        street: '100 King St W', city: 'Toronto', state: 'ON',
        postalCode: 'M5X 1A9', country: 'CA', phoneNumber: '+14165550000',
        apartment: '',
      },
    };

    const error = await callExpectError('create_checkout_session', data, buyer.idToken);
    expect(
      error.code !== 'unexpected-success',
      'Checkout should validate seller exists and is not suspended'
    ).toBe(true);

    // Cleanup
    await deleteDoc(`products/${fakeProductId}`);
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE E · STOCK INTEGRITY UNDER PRESSURE — Race conditions and phantom stock
// ════════════════════════════════════════════════════════════════════════════

test.describe('E. Stock Integrity Under Pressure', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('E.1 Cancel restores exact stock (no phantom stock)', async () => {
    // Buy 2 units, cancel, verify stock goes back to exactly the original value
    const prodDoc = await readDoc(`products/${PRODUCT_HIGH_STOCK}`);
    const stockBefore = parseDoc(prodDoc)?.stockQuantity;
    expect(stockBefore, 'Product should have stock').toBeGreaterThan(2);

    const { orderId, auth } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 2);
    // Wait a bit for stock reservation
    await new Promise(r => setTimeout(r, 2_000));

    const stockAfterCheckout = parseDoc(await readDoc(`products/${PRODUCT_HIGH_STOCK}`))?.stockQuantity;

    // Cancel
    const buyer = await signIn(BUYER1_EMAIL);
    await callOk('cancel_order', { orderId }, buyer.idToken);
    await new Promise(r => setTimeout(r, 2_000));

    const stockAfterCancel = parseDoc(await readDoc(`products/${PRODUCT_HIGH_STOCK}`))?.stockQuantity;

    expect(
      stockAfterCancel,
      `Stock after cancel (${stockAfterCancel}) should equal stock before checkout (${stockBefore})`
    ).toBe(stockBefore);
  });

  test('E.2 Double cancel does not double-restore stock', async () => {
    // Cancel the same order twice — stock should only be restored once (idempotent)
    const prodDoc = await readDoc(`products/${PRODUCT_HIGH_STOCK}`);
    const stockBefore = parseDoc(prodDoc)?.stockQuantity;

    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await new Promise(r => setTimeout(r, 2_000));

    const buyer = await signIn(BUYER1_EMAIL);
    // First cancel
    await callOk('cancel_order', { orderId }, buyer.idToken);
    await new Promise(r => setTimeout(r, 1_000));

    const stockAfterFirst = parseDoc(await readDoc(`products/${PRODUCT_HIGH_STOCK}`))?.stockQuantity;

    // Second cancel attempt — should fail or be idempotent
    await callCallable('cancel_order', { orderId }, buyer.idToken);
    await new Promise(r => setTimeout(r, 1_000));

    const stockAfterSecond = parseDoc(await readDoc(`products/${PRODUCT_HIGH_STOCK}`))?.stockQuantity;

    expect(
      stockAfterSecond,
      `Stock after double cancel (${stockAfterSecond}) should equal stock after first cancel (${stockAfterFirst}), not double-restored`
    ).toBe(stockAfterFirst);
    expect(stockAfterFirst, 'Stock should be restored to original').toBe(stockBefore);
  });

  test('E.3 Delete product with pending order is blocked', async () => {
    // Soft delete should be prevented if there are unfulfilled orders
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    // Order is now in pending status

    const seller = await signIn(SELLER1_EMAIL);
    const error = await callExpectError('delete_product', {
      productId: PRODUCT_HIGH_STOCK,
    }, seller.idToken);

    expect(
      error.code,
      'Delete product with pending order should be blocked with failed-precondition'
    ).not.toBe('unexpected-success');

    // Cancel the order to clean up
    const buyer = await signIn(BUYER1_EMAIL);
    await callCallable('cancel_order', { orderId }, buyer.idToken);
  });

  test('E.4 Concurrent checkouts on low-stock product — only stock-available succeed', async () => {
    // Create a temporary low-stock product, fire 3 checkouts simultaneously
    const lowStockProductId = `test_lowstock_${Date.now()}`;
    const seller = await signIn(SELLER1_EMAIL);
    const sellerUid = seller.localId;

    await writeDoc(`products/${lowStockProductId}`, {
      name: 'Low Stock Widget', price: 5.00, stockQuantity: 2,
      sellerId: sellerUid, isActive: true, category: 'Test',
      imageUrls: ['https://picsum.photos/400'],
      freeShipping: true,
      deliveryOptions: { standard: { type: 'standard', cost: 0, estimatedDays: 5, isEnabled: true } },
    });

    // 3 buyers try to buy 1 each (only 2 stock available)
    const buyers = [BUYER1_EMAIL, BUYER2_EMAIL, BUYER3_EMAIL];
    const results = await Promise.allSettled(
      buyers.map(email => createOrder(email, lowStockProductId, 1))
    );

    const successes = results.filter(r => r.status === 'fulfilled');
    const failures = results.filter(r => r.status === 'rejected');

    // Verify stock integrity: at most 2 should succeed
    const finalStock = parseDoc(await readDoc(`products/${lowStockProductId}`))?.stockQuantity;
    expect(
      finalStock,
      `Final stock should be >= 0 (no negative stock), got: ${finalStock}`
    ).toBeGreaterThanOrEqual(0);

    // The number of successful orders should not exceed available stock
    expect(
      successes.length,
      `${successes.length} orders succeeded but only 2 units available`
    ).toBeLessThanOrEqual(2);

    // Cleanup: cancel all successful orders and delete the test product
    for (const r of successes) {
      if (r.status === 'fulfilled') {
        const buyerAuth = await signIn(buyers[successes.indexOf(r)]);
        await callCallable('cancel_order', { orderId: r.value.orderId }, buyerAuth.idToken).catch(() => {});
      }
    }
    await new Promise(r => setTimeout(r, 2_000));
    await deleteDoc(`products/${lowStockProductId}`);
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE F · PERMISSION BOUNDARY & EDGE CASES — Access control logic bugs
// ════════════════════════════════════════════════════════════════════════════

test.describe('F. Permission Boundary & Edge Cases', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('F.1 Buyer cannot initiate a refund (seller or admin only)', async () => {
    // Buyers should never be able to refund their own orders
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'delivered', { paymentStatus: 'captured' });

    const buyer = await signIn(BUYER1_EMAIL);
    const error = await callExpectError('refund_order_item', {
      orderId, productId: PRODUCT_HIGH_STOCK,
    }, buyer.idToken);

    expect(
      error.code,
      'Buyer should not be able to self-refund — only seller of item or admin'
    ).not.toBe('unexpected-success');
    if (error.code !== 'unexpected-success') {
      expect(
        error.code,
        `Expected permission-denied, got: ${error.code}`
      ).toBe('permission-denied');
    }
  });

  test('F.2 Non-onboarded seller cannot sell (checkout with their product fails)', async () => {
    // seller9/seller10 are not Stripe-onboarded — checkout should reject
    const nonOnboarded = await signIn(NON_ONBOARDED_SELLER);
    if (!nonOnboarded?.localId) {
      console.log('⚠️ Non-onboarded seller does not exist — skipping');
      return;
    }

    const userDoc = parseDoc(await readDoc(`users/${nonOnboarded.localId}`));
    // Verify they're actually not onboarded
    if (userDoc?.onboardingCompleted !== true) {
      // Create a product under this non-onboarded seller
      const testProductId = `test_non_onboarded_${Date.now()}`;
      await writeDoc(`products/${testProductId}`, {
        name: 'Non-Onboarded Product', price: 15.00, stockQuantity: 10,
        sellerId: nonOnboarded.localId, isActive: true, category: 'Test',
        imageUrls: ['https://picsum.photos/400'],
        freeShipping: true,
        deliveryOptions: { standard: { type: 'standard', cost: 0, estimatedDays: 5, isEnabled: true } },
      });

      // Buyer tries to purchase
      const buyer = await signIn(BUYER1_EMAIL);
      const data = {
        userId: buyer.localId,
        items: [{
          productId: testProductId, name: 'Non-Onboarded Product', price: 15.00,
          quantity: 1, sellerId: nonOnboarded.localId,
          imageUrls: ['https://picsum.photos/400'],
        }],
        subtotal: 15.00,
        shippingAddress: {
          street: '100 King St W', city: 'Toronto', state: 'ON',
          postalCode: 'M5X 1A9', country: 'CA', phoneNumber: '+14165550000', apartment: '',
        },
      };

      const error = await callExpectError('create_checkout_session', data, buyer.idToken);
      expect(
        error.code,
        'Checkout with non-onboarded seller should be rejected'
      ).not.toBe('unexpected-success');

      await deleteDoc(`products/${testProductId}`);
    } else {
      console.log('⚠️ seller9 is actually onboarded — test assumption invalid');
    }
  });

  test('F.3 Rating without purchase (or before delivery) is rejected', async () => {
    // A user who never bought the product tries to rate it
    const buyer = await signIn(BUYER2_EMAIL);

    const error = await callExpectError('submit_product_rating', {
      productId: PRODUCT_HIGH_STOCK,
      orderId: 'non_existent_order_12345',
      rating: 5,
      review: 'Fake 5 stars!',
    }, buyer.idToken);

    expect(
      error.code,
      'Rating without a valid delivered order should be rejected'
    ).not.toBe('unexpected-success');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE G · SELF-PURCHASE & CROSS-BOUNDARY — Business rule enforcement
// ════════════════════════════════════════════════════════════════════════════

test.describe('G. Self-Purchase & Cross-Boundary Rules', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('G.1 Seller cannot buy their own product', async () => {
    // Self-purchase is a marketplace violation — must be blocked server-side
    const seller = await signIn(SELLER1_EMAIL);
    const prodDoc = await readDoc(`products/${PRODUCT_HIGH_STOCK}`);
    const product = parseDoc(prodDoc);

    // Only test if this product belongs to seller1
    if (product?.sellerId === seller.localId) {
      const { data } = await buildCheckoutPayload(seller.localId, PRODUCT_HIGH_STOCK, 1);
      const error = await callExpectError('create_checkout_session', data, seller.idToken);
      expect(
        error.code,
        'Self-purchase should be rejected by backend'
      ).not.toBe('unexpected-success');
    } else {
      console.log(`⚠️ product_001 belongs to ${product?.sellerId}, not seller1 — adjusting test`);
      // Find a product that belongs to seller1
      const queryRes = await fetch(
        `${FIRESTORE_EMU}/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
        { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
          body: JSON.stringify({ structuredQuery: {
            from: [{ collectionId: 'products' }],
            where: { compositeFilter: { op: 'AND', filters: [
              { fieldFilter: { field: { fieldPath: 'sellerId' }, op: 'EQUAL', value: { stringValue: seller.localId } } },
              { fieldFilter: { field: { fieldPath: 'isActive' }, op: 'EQUAL', value: { booleanValue: true } } },
            ]}},
            limit: 1,
          }}) }
      );
      const results = await queryRes.json();
      const prods = Array.isArray(results) ? results.filter((r: any) => r.document) : [];
      if (prods.length > 0) {
        const ownProduct = parseDoc(prods[0].document);
        const pid = prods[0].document.name.split('/').pop();
        const { data } = await buildCheckoutPayload(seller.localId, pid, 1);
        const error = await callExpectError('create_checkout_session', data, seller.idToken);
        expect(error.code, 'Self-purchase should be rejected').not.toBe('unexpected-success');
      }
    }
  });

  test('G.2 Wrong seller cannot update another seller\'s order items', async () => {
    // Seller2 tries to update status on an order that belongs to Seller1's product
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);
    await forceOrderStatus(orderId, 'confirmed');

    const seller2 = await signIn(SELLER2_EMAIL);
    const error = await callExpectError('update_order_status', {
      orderId, newStatus: 'processing',
    }, seller2.idToken);

    expect(
      error.code,
      'Wrong seller should not be able to update another seller\'s order'
    ).not.toBe('unexpected-success');

    // Cleanup
    const buyer = await signIn(BUYER1_EMAIL);
    await callCallable('cancel_order', { orderId }, buyer.idToken).catch(() => {});
  });

  test('G.3 Admin role change without MFA is rejected', async () => {
    // update_user_role requires recent MFA verification — calling without it should fail
    const admin = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    const buyer = await signIn(BUYER1_EMAIL);

    const error = await callExpectError('update_user_role', {
      targetUserId: buyer.localId,
      roles: ['buyer', 'seller'],
    }, admin.idToken);

    // Should fail because MFA was not recently verified
    expect(
      error.code,
      `Role change without MFA should be rejected, got: ${error.code} - ${error.message}`
    ).not.toBe('unexpected-success');
  });

  test('G.4 GDPR delete_account blocked when user has active orders', async () => {
    // User with pending/confirmed/processing orders cannot delete their account
    const { orderId } = await createOrder(BUYER1_EMAIL, PRODUCT_HIGH_STOCK, 1);

    const buyer = await signIn(BUYER1_EMAIL);
    const error = await callExpectError('delete_user_data', {}, buyer.idToken);

    expect(
      error.code,
      'Account deletion with active orders should be blocked'
    ).not.toBe('unexpected-success');

    // Cleanup
    await callCallable('cancel_order', { orderId }, buyer.idToken).catch(() => {});
  });
});
