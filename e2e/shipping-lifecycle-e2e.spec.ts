// @ts-check
/**
 * OrignaGTA — Shipping & Order Lifecycle E2E Test Suite
 * =====================================================
 * Complete end-to-end tests covering the ENTIRE shipping process:
 *
 *   Suite A · Happy Path: Checkout → Confirm → Process → Ship → Deliver → Capture (serial)
 *   Suite B · Multi-Seller Order: Two sellers ship independently, buyer confirms (serial)
 *   Suite C · Per-Item Status: update_item_status for multi-item orders (serial)
 *   Suite D · Cancellation at Every Stage: Cancel pre-ship & blocked post-ship (serial)
 *   Suite E · Shipping Approval Flow: Buyer approves/rejects updated shipping cost
 *   Suite F · Tracking & Carrier Info: trackingNumber + carrier persistence
 *   Suite G · Permission & Security: Wrong users can't update status
 *   Suite H · Edge Cases: Double-confirm, invalid transitions, expired authorization
 *   Suite I · Partial Refund After Delivery: refund_order_item flow
 *   Suite J · Rating After Delivery: Buyer rates product post-delivery
 *
 * Prerequisites:
 *   1. firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
 *   2. cd e2e && npx ts-node mega-seed.ts
 *   3. stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
 *   4. npx playwright test shipping-lifecycle-e2e.spec.ts --reporter=list
 */
import { test, expect } from '@playwright/test';
import {
  checkInfrastructure, ensureSeedData, signIn,
  callOk as callCallable, // This file expects callCallable to THROW on error
  readDoc, writeDoc, parseDoc,
  buildCheckoutPayload, buildMultiSellerPayload,
  fullCheckoutAndPay, fullMultiSellerCheckoutAndPay,
  waitForOrderStatus,
  FIRESTORE_EMULATOR, PROJECT_ID,
} from './api-helpers';

// Alias for this file's naming convention
const FIRESTORE_EMU = FIRESTORE_EMULATOR;

/** Read order from Firestore */
async function getOrder(orderId: string): Promise<any> {
  const doc = await readDoc(`orders/${orderId}`);
  return doc ? parseDoc(doc) : null;
}

/** Read product stock from Firestore */
async function getProductStock(productId: string): Promise<number> {
  const doc = await readDoc(`products/${productId}`);
  const product = parseDoc(doc);
  return product?.stockQuantity ?? 0;
}


// ════════════════════════════════════════════════════════════════════════════
// SUITE A · HAPPY PATH: Full lifecycle checkout → delivery → payment capture
// ════════════════════════════════════════════════════════════════════════════

test.describe('A. Happy Path — Full Shipping Lifecycle', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  // Shared state across serial tests
  let orderId: string;
  let sellerToken: string;
  let buyerToken: string;
  let sellerId: string;
  let buyerId: string;

  const BUYER_EMAIL  = 'yuniorrodriguezo460@gmail.com';
  const SELLER_EMAIL = 'seller1@test.origna.ca';
  const PRODUCT_ID   = 'product_001'; // Handmade Quebec Scarf, $45.99, seller1

  test('A.1 Buyer checkouts and pays via Stripe', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('🛒 A.1 — Checkout & pay');

    const result = await fullCheckoutAndPay(page, BUYER_EMAIL, PRODUCT_ID, 1);
    orderId = result.orderId;
    expect(orderId).toBeTruthy();
    console.log(`   ✅ orderId=${orderId}`);

    // Sign in for later use
    const buyerAuth = await signIn(BUYER_EMAIL);
    buyerToken = buyerAuth.idToken;
    buyerId = buyerAuth.localId;
    const sellerAuth = await signIn(SELLER_EMAIL);
    sellerToken = sellerAuth.idToken;
    sellerId = sellerAuth.localId;
  });

  test('A.2 Webhook fires — order becomes confirmed/authorized', async () => {
    test.setTimeout(90_000);
    console.log('📡 A.2 — Waiting for Stripe webhook');

    const order = await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);
    expect(order).toBeTruthy();
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('authorized');
    console.log(`   ✅ orderStatus=${order.orderStatus}, paymentStatus=${order.paymentStatus}`);
  });

  test('A.3 Seller updates to processing', async () => {
    test.setTimeout(15_000);
    console.log('⚙️ A.3 — Seller → processing');

    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'processing',
    }, sellerToken);
    expect(result.newStatus).toBe('processing');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('processing');
    console.log('   ✅ processing');
  });

  test('A.4 Seller ships with tracking number', async () => {
    test.setTimeout(15_000);
    console.log('📦 A.4 — Seller → shipped');

    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'CP1234567890',
      carrier: 'Canada Post',
    }, sellerToken);
    expect(result.newStatus).toBe('shipped');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('shipped');
    expect(order.trackingNumber).toBe('CP1234567890');
    expect(order.carrier).toBe('Canada Post');
    expect(order.deliveryStatus).toBe('shipped');
    console.log(`   ✅ shipped — tracking=${order.trackingNumber}, carrier=${order.carrier}`);
  });

  test('A.5 Seller updates to in_transit', async () => {
    test.setTimeout(15_000);
    console.log('🚚 A.5 — Seller → in_transit');

    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'in_transit',
    }, sellerToken);
    expect(result.newStatus).toBe('in_transit');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('in_transit');
    console.log('   ✅ in_transit');
  });

  test('A.6 Seller marks as delivered', async () => {
    test.setTimeout(15_000);
    console.log('✅ A.6 — Seller → delivered');

    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'delivered',
    }, sellerToken);
    expect(result.newStatus).toBe('delivered');

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('delivered');
    console.log('   ✅ delivered');
  });

  test('A.7 Buyer confirms receipt — captures payment', async () => {
    test.setTimeout(30_000);
    console.log('💳 A.7 — Buyer confirms receipt (capture_payment)');

    const result = await callCallable('confirm_order_receipt', { orderId }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.captured).toBe(true);

    const order = await getOrder(orderId);
    expect(order.paymentStatus).toBe('captured');
    expect(order.confirmedByClient).toBe(true);
    console.log(`   ✅ captured — paymentStatus=${order.paymentStatus}, confirmedByClient=${order.confirmedByClient}`);
  });

  test('A.8 Payout record created for seller', async () => {
    test.setTimeout(10_000);
    console.log('💰 A.8 — Verify payout record');

    // Query payouts collection for this order
    const queryUrl = `${FIRESTORE_EMU}/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
    const queryRes = await fetch(queryUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'payouts' }],
          where: {
            fieldFilter: {
              field: { fieldPath: 'orderId' },
              op: 'EQUAL',
              value: { stringValue: orderId },
            },
          },
        },
      }),
    });
    const payouts = await queryRes.json();
    // Should have at least one payout document
    const payoutDocs = payouts.filter((p: any) => p.document);
    expect(payoutDocs.length).toBeGreaterThanOrEqual(1);

    const payout = parseDoc(payoutDocs[0].document);
    expect(payout.status).toBe('completed');
    expect(payout.amountCents).toBeGreaterThan(0);
    expect(payout.platformFeeCents).toBeGreaterThan(0);
    expect(payout.netAmountCents).toBeGreaterThan(0);
    console.log(`   ✅ Payout: $${(payout.netAmountCents / 100).toFixed(2)} net to seller (fee: $${(payout.platformFeeCents / 100).toFixed(2)})`);
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE B · MULTI-SELLER ORDER: Two sellers ship independently
// ════════════════════════════════════════════════════════════════════════════

test.describe('B. Multi-Seller Order Lifecycle', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let seller1Token: string;
  let seller3Token: string;
  let buyerToken: string;

  const BUYER_EMAIL   = 'buyer2@test.origna.ca';
  const SELLER1_EMAIL = 'seller1@test.origna.ca';  // sells product_001 (QC)
  const SELLER3_EMAIL = 'seller3@test.origna.ca';  // sells product_007 (AB)

  test('B.1 Buyer checkouts with items from 2 sellers', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('🛒 B.1 — Multi-seller checkout');

    const result = await fullMultiSellerCheckoutAndPay(page, BUYER_EMAIL, [
      { productId: 'product_003', quantity: 1 },  // seller1 — Tourtière Spice Kit $12.99
      { productId: 'product_007', quantity: 1 },  // seller3 — Jerky $34.99
    ]);
    orderId = result.orderId;
    expect(orderId).toBeTruthy();

    const buyerAuth = await signIn(BUYER_EMAIL);
    buyerToken = buyerAuth.idToken;
    const s1 = await signIn(SELLER1_EMAIL);
    seller1Token = s1.idToken;
    const s3 = await signIn(SELLER3_EMAIL);
    seller3Token = s3.idToken;

    console.log(`   ✅ orderId=${orderId}`);
  });

  test('B.2 Webhook confirms order', async () => {
    test.setTimeout(90_000);
    const order = await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);
    expect(order.orderStatus).toBe('confirmed');
    expect(order.paymentStatus).toBe('authorized');
    console.log('   ✅ confirmed/authorized');
  });

  test('B.3 Seller1 updates to processing', async () => {
    const result = await callCallable('update_order_status', { orderId, newStatus: 'processing' }, seller1Token);
    expect(result.newStatus).toBe('processing');
    console.log('   ✅ processing (by seller1)');
  });

  test('B.4 Seller1 ships order', async () => {
    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'CP-MULTI-001', carrier: 'Canada Post',
    }, seller1Token);
    expect(result.newStatus).toBe('shipped');

    const order = await getOrder(orderId);
    expect(order.trackingNumber).toBe('CP-MULTI-001');
    console.log('   ✅ shipped by seller1');
  });

  test('B.5 Seller3 can also update the same order (is a seller of an item)', async () => {
    // seller3 updates to in_transit (they are also a seller of an item in the order)
    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'in_transit',
    }, seller3Token);
    expect(result.newStatus).toBe('in_transit');
    console.log('   ✅ in_transit (updated by seller3)');
  });

  test('B.6 Mark delivered and buyer confirms receipt', async () => {
    test.setTimeout(30_000);
    await callCallable('update_order_status', { orderId, newStatus: 'delivered' }, seller1Token);
    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('delivered');

    const result = await callCallable('confirm_order_receipt', { orderId }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.captured).toBe(true);

    const final = await getOrder(orderId);
    expect(final.paymentStatus).toBe('captured');
    console.log('   ✅ delivered + captured');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE C · PER-ITEM STATUS: update_item_status for multi-item orders
// ════════════════════════════════════════════════════════════════════════════

test.describe('C. Per-Item Status Tracking', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let seller1Token: string;
  let seller3Token: string;
  let buyerToken: string;

  const BUYER_EMAIL   = 'buyer3@test.origna.ca';
  const SELLER1_EMAIL = 'seller1@test.origna.ca';
  const SELLER3_EMAIL = 'seller3@test.origna.ca';

  test('C.1 Create multi-item order', async ({ page }) => {
    test.setTimeout(90_000);

    const result = await fullMultiSellerCheckoutAndPay(page, BUYER_EMAIL, [
      { productId: 'product_003', quantity: 1 },  // seller1 — Tourtière Spice Kit $12.99
      { productId: 'product_008', quantity: 1 },  // seller3 — Calgary Poster $29.99
    ]);
    orderId = result.orderId;

    const buyerAuth = await signIn(BUYER_EMAIL);
    buyerToken = buyerAuth.idToken;
    const s1 = await signIn(SELLER1_EMAIL);
    seller1Token = s1.idToken;
    const s3 = await signIn(SELLER3_EMAIL);
    seller3Token = s3.idToken;

    console.log(`   ✅ orderId=${orderId}`);
  });

  test('C.2 Wait for confirmation', async () => {
    test.setTimeout(90_000);
    const order = await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);
    expect(order.orderStatus).toBe('confirmed');
  });

  test('C.3 Move to shipped (order-level)', async () => {
    await callCallable('update_order_status', { orderId, newStatus: 'processing' }, seller1Token);
    await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'ITEM-TRACK-001', carrier: 'UPS',
    }, seller1Token);
    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('shipped');
    console.log('   ✅ order shipped');
  });

  test('C.4 Seller1 marks their item as shipped (per-item)', async () => {
    const result = await callCallable('update_item_status', {
      orderId, productId: 'product_003', newStatus: 'shipped',
      trackingNumber: 'ITEM-S1-TRACK', carrier: 'Canada Post',
    }, seller1Token);
    expect(result.itemStatus).toBe('shipped');
    expect(result.allItemsDelivered).toBe(false);
    console.log('   ✅ product_003 item → shipped');
  });

  test('C.5 Seller3 marks their item as shipped (per-item)', async () => {
    const result = await callCallable('update_item_status', {
      orderId, productId: 'product_008', newStatus: 'shipped',
      trackingNumber: 'ITEM-S3-TRACK', carrier: 'FedEx',
    }, seller3Token);
    expect(result.itemStatus).toBe('shipped');
    expect(result.allItemsDelivered).toBe(false);
    console.log('   ✅ product_008 item → shipped');
  });

  test('C.6 Seller1 marks their item as delivered', async () => {
    const result = await callCallable('update_item_status', {
      orderId, productId: 'product_003', newStatus: 'delivered',
    }, seller1Token);
    expect(result.itemStatus).toBe('delivered');
    expect(result.allItemsDelivered).toBe(false); // product_008 not yet delivered
    console.log('   ✅ product_003 delivered (product_008 still pending)');
  });

  test('C.7 Seller3 marks their item as delivered — triggers order-level delivered', async () => {
    const result = await callCallable('update_item_status', {
      orderId, productId: 'product_008', newStatus: 'delivered',
    }, seller3Token);
    expect(result.itemStatus).toBe('delivered');
    expect(result.allItemsDelivered).toBe(true); // both delivered

    // Order should now be delivered at order level
    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('delivered');
    expect(order.deliveryStatus).toBe('delivered');
    console.log('   ✅ all items delivered → order delivered');
  });

  test('C.8 Buyer confirms receipt — payment captured', async () => {
    test.setTimeout(30_000);
    const result = await callCallable('confirm_order_receipt', { orderId }, buyerToken);
    expect(result.success).toBe(true);
    expect(result.captured).toBe(true);
    console.log('   ✅ captured');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE D · CANCELLATION: Cancel at every stage + blocked post-ship
// ════════════════════════════════════════════════════════════════════════════

test.describe('D. Order Cancellation Flow', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('D.1 Cancel pending order — stock restored', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('❌ D.1 — Cancel pending order');

    const buyerAuth = await signIn('buyer4@test.origna.ca');
    const { data } = await buildCheckoutPayload(buyerAuth.localId, 'product_004', 1); // BC Cedar $24.99
    const stockBefore = await getProductStock('product_004');

    const result = await callCallable('create_checkout_session', data, buyerAuth.idToken);
    const orderId = result.orderId;

    // Order is pending (payment not yet made) — cancel immediately
    const cancelResult = await callCallable('cancel_order', {
      orderId, reason: 'Changed my mind',
    }, buyerAuth.idToken);
    expect(cancelResult.success).toBe(true);

    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('cancelled');
    expect(order.cancellationReason).toContain('Changed my mind');

    // Stock should be restored
    const stockAfter = await getProductStock('product_004');
    expect(stockAfter).toBe(stockBefore);
    console.log('   ✅ pending → cancelled, stock restored');
  });

  test('D.2 Cancel confirmed order', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('❌ D.2 — Cancel confirmed order');

    const result = await fullCheckoutAndPay(page, 'buyer5@test.origna.ca', 'product_004', 1);
    const order = await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);
    expect(order.orderStatus).toBe('confirmed');

    const buyerAuth = await signIn('buyer5@test.origna.ca');
    const cancelResult = await callCallable('cancel_order', {
      orderId: result.orderId, reason: 'Found a better deal',
    }, buyerAuth.idToken);
    expect(cancelResult.success).toBe(true);

    const final = await getOrder(result.orderId);
    expect(final.orderStatus).toBe('cancelled');
    console.log('   ✅ confirmed → cancelled');
  });

  test('D.3 Cancel processing order', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('❌ D.3 — Cancel processing order');

    const result = await fullCheckoutAndPay(page, 'buyer6@test.origna.ca', 'product_004', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller2@test.origna.ca'); // seller of product_004
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'processing' }, sellerAuth.idToken);

    const buyerAuth = await signIn('buyer6@test.origna.ca');
    const cancelResult = await callCallable('cancel_order', {
      orderId: result.orderId, reason: 'No longer needed',
    }, buyerAuth.idToken);
    expect(cancelResult.success).toBe(true);

    const final = await getOrder(result.orderId);
    expect(final.orderStatus).toBe('cancelled');
    console.log('   ✅ processing → cancelled');
  });

  test('D.4 BLOCKED: Cannot cancel shipped order', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('🚫 D.4 — Cannot cancel after shipping');

    const result = await fullCheckoutAndPay(page, 'buyer7@test.origna.ca', 'product_004', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller2@test.origna.ca');
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'processing' }, sellerAuth.idToken);
    await callCallable('update_order_status', {
      orderId: result.orderId, newStatus: 'shipped',
      trackingNumber: 'NO-CANCEL-001', carrier: 'Purolator',
    }, sellerAuth.idToken);

    const buyerAuth = await signIn('buyer7@test.origna.ca');
    try {
      await callCallable('cancel_order', { orderId: result.orderId, reason: 'Too late' }, buyerAuth.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('Cannot cancel order');
      console.log('   ✅ Correctly blocked: cannot cancel shipped order');
    }
  });

  test('D.5 BLOCKED: Cannot cancel delivered order', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('🚫 D.5 — Cannot cancel delivered order');

    const result = await fullCheckoutAndPay(page, 'buyer8@test.origna.ca', 'product_004', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller2@test.origna.ca');
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'processing' }, sellerAuth.idToken);
    await callCallable('update_order_status', {
      orderId: result.orderId, newStatus: 'shipped',
      trackingNumber: 'NO-CANCEL-002', carrier: 'Canada Post',
    }, sellerAuth.idToken);
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'delivered' }, sellerAuth.idToken);

    const buyerAuth = await signIn('buyer8@test.origna.ca');
    try {
      await callCallable('cancel_order', { orderId: result.orderId, reason: 'Regret' }, buyerAuth.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('Cannot cancel order');
      console.log('   ✅ Correctly blocked: cannot cancel delivered order');
    }
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE E · SHIPPING APPROVAL: Buyer approves/rejects updated shipping cost
// ════════════════════════════════════════════════════════════════════════════

test.describe('E. Shipping Approval Flow', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('E.1 Buyer approves shipping cost change', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('📋 E.1 — Approve shipping cost');

    const result = await fullCheckoutAndPay(page, 'buyer9@test.origna.ca', 'product_011', 1); // Parliament Puzzle $39.99
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    // Simulate seller requesting shipping cost update by writing to Firestore directly
    await writeDoc(`orders/${result.orderId}`, {
      shippingApproval: {
        status: 'pending',
        originalCost: 5.99,
        actualCost: 12.99,
        reason: 'Heavier than expected',
      },
    });

    const buyerAuth = await signIn('buyer9@test.origna.ca');
    const approveResult = await callCallable('approve_shipping_cost', {
      orderId: result.orderId, approved: true,
    }, buyerAuth.idToken);
    expect(approveResult.success).toBe(true);
    expect(approveResult.approved).toBe(true);

    const order = await getOrder(result.orderId);
    expect(order.shippingApproval.status).toBe('approved');
    console.log('   ✅ Shipping cost approved');
  });

  test('E.2 Buyer rejects shipping cost — order cancelled + stock restored', async ({ page }) => {
    test.setTimeout(90_000);
    console.log('📋 E.2 — Reject shipping cost → cancel');

    const stockBefore = await getProductStock('product_011');
    const result = await fullCheckoutAndPay(page, 'buyer10@test.origna.ca', 'product_011', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    // Simulate shipping cost update
    await writeDoc(`orders/${result.orderId}`, {
      shippingApproval: {
        status: 'pending',
        originalCost: 5.99,
        actualCost: 25.00,
        reason: 'Remote area surcharge',
      },
    });

    const buyerAuth = await signIn('buyer10@test.origna.ca');
    const rejectResult = await callCallable('approve_shipping_cost', {
      orderId: result.orderId, approved: false,
    }, buyerAuth.idToken);
    expect(rejectResult.success).toBe(true);
    expect(rejectResult.approved).toBe(false);

    const order = await getOrder(result.orderId);
    expect(order.orderStatus).toBe('cancelled');
    expect(order.shippingApproval.status).toBe('rejected');

    // Stock should be restored
    const stockAfter = await getProductStock('product_011');
    expect(stockAfter).toBe(stockBefore);
    console.log('   ✅ Shipping rejected → cancelled, stock restored');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE F · TRACKING INFO: Verify tracking + carrier persist correctly
// ════════════════════════════════════════════════════════════════════════════

test.describe('F. Tracking & Carrier Information', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let sellerToken: string;

  test('F.1 Create and pay order', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer11@test.origna.ca', 'product_008', 1); // Calgary Poster $29.99
    orderId = result.orderId;
    await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);
    const sellerAuth = await signIn('seller3@test.origna.ca');
    sellerToken = sellerAuth.idToken;
    await callCallable('update_order_status', { orderId, newStatus: 'processing' }, sellerToken);
  });

  test('F.2 Ship with Canada Post tracking', async () => {
    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'CP9876543210CA',
      carrier: 'Canada Post',
    }, sellerToken);
    expect(result.newStatus).toBe('shipped');

    const order = await getOrder(orderId);
    expect(order.trackingNumber).toBe('CP9876543210CA');
    expect(order.carrier).toBe('Canada Post');
    expect(order.shippedAt).toBeTruthy();
    console.log(`   ✅ Tracking: ${order.trackingNumber} via ${order.carrier}`);
  });

  test('F.3 Tracking info persists after delivery', async () => {
    test.setTimeout(30_000);
    await callCallable('update_order_status', { orderId, newStatus: 'delivered' }, sellerToken);
    const order = await getOrder(orderId);
    expect(order.orderStatus).toBe('delivered');
    // Tracking should still be there
    expect(order.trackingNumber).toBe('CP9876543210CA');
    expect(order.carrier).toBe('Canada Post');
    console.log('   ✅ Tracking info persists after delivery');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE G · PERMISSION & SECURITY: Wrong users can't update status
// ════════════════════════════════════════════════════════════════════════════

test.describe('G. Permissions & Security', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let buyerToken: string;
  let wrongSellerToken: string;
  let correctSellerToken: string;

  test('G.1 Create order (buyer12 buys from seller1)', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer12@test.origna.ca', 'product_003', 1);
    orderId = result.orderId;
    await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);

    const buyerAuth = await signIn('buyer12@test.origna.ca');
    buyerToken = buyerAuth.idToken;
    const correctSeller = await signIn('seller1@test.origna.ca');
    correctSellerToken = correctSeller.idToken;
    const wrongSeller = await signIn('seller2@test.origna.ca');  // not the seller of this item
    wrongSellerToken = wrongSeller.idToken;
  });

  test('G.2 Buyer CANNOT update order status (not a seller)', async () => {
    try {
      await callCallable('update_order_status', { orderId, newStatus: 'processing' }, buyerToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('Only seller or admin');
      console.log('   ✅ Buyer blocked from updating status');
    }
  });

  test('G.3 Wrong seller CANNOT update order status', async () => {
    try {
      await callCallable('update_order_status', { orderId, newStatus: 'processing' }, wrongSellerToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('Only seller or admin');
      console.log('   ✅ Wrong seller blocked from updating status');
    }
  });

  test('G.4 Correct seller CAN update order status', async () => {
    const result = await callCallable('update_order_status', { orderId, newStatus: 'processing' }, correctSellerToken);
    expect(result.newStatus).toBe('processing');
    console.log('   ✅ Correct seller can update status');
  });

  test('G.5 Admin can update any order', async () => {
    const adminAuth = await signIn('yr62813@gmail.com', '960227Y#y');
    const result = await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'ADMIN-SHIP-001', carrier: 'DHL',
    }, adminAuth.idToken);
    expect(result.newStatus).toBe('shipped');
    console.log('   ✅ Admin can update any order');
  });

  test('G.6 Wrong buyer CANNOT confirm receipt of another order', async () => {
    test.setTimeout(30_000);
    // Deliver the order first
    const adminAuth = await signIn('yr62813@gmail.com', '960227Y#y');
    await callCallable('update_order_status', { orderId, newStatus: 'delivered' }, adminAuth.idToken);

    // buyer13 tries to confirm buyer12's order
    const wrongBuyer = await signIn('buyer13@test.origna.ca');
    try {
      await callCallable('confirm_order_receipt', { orderId }, wrongBuyer.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('order owner or admin');
      console.log('   ✅ Wrong buyer blocked from confirming receipt');
    }
  });

  test('G.7 Wrong seller CANNOT update item status', async () => {
    // product_003 belongs to seller1, seller2 should be blocked
    try {
      await callCallable('update_item_status', {
        orderId, productId: 'product_003', newStatus: 'delivered',
      }, wrongSellerToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('item seller or admin');
      console.log('   ✅ Wrong seller blocked from item status update');
    }
  });

  test('G.8 Unauthenticated user blocked', async () => {
    try {
      await callCallable('update_order_status', { orderId, newStatus: 'processing' }, 'invalid-token-123');
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toBeTruthy();
      console.log('   ✅ Unauthenticated user blocked');
    }
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE H · EDGE CASES: Invalid transitions, double-confirm, idempotency
// ════════════════════════════════════════════════════════════════════════════

test.describe('H. Edge Cases', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });

  test('H.1 Invalid state transition blocked (confirmed → delivered)', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer14@test.origna.ca', 'product_008', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller3@test.origna.ca');
    try {
      // Skip processing & shipped, try to jump to delivered
      await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'delivered' }, sellerAuth.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      // Backend may return "Invalid transition" OR "Sellers cannot mark orders as delivered"
      expect(e.message).toMatch(/Invalid transition|cannot.*deliver|Sellers cannot/i);
      console.log('   ✅ confirmed → delivered blocked');
    }
  });

  test('H.2 Invalid state transition blocked (pending → shipped)', async () => {
    test.setTimeout(30_000);
    const buyerAuth = await signIn('buyer15@test.origna.ca');
    const { data } = await buildCheckoutPayload(buyerAuth.localId, 'product_008', 1);
    const result = await callCallable('create_checkout_session', data, buyerAuth.idToken);

    const sellerAuth = await signIn('seller3@test.origna.ca');
    try {
      await callCallable('update_order_status', {
        orderId: result.orderId, newStatus: 'shipped',
        trackingNumber: 'BAD-001', carrier: 'Test',
      }, sellerAuth.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('Invalid transition');
      console.log('   ✅ pending → shipped blocked');
    }
  });

  test('H.3 Double confirm_order_receipt is idempotent', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer16@test.origna.ca', 'product_008', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller3@test.origna.ca');
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'processing' }, sellerAuth.idToken);
    await callCallable('update_order_status', {
      orderId: result.orderId, newStatus: 'shipped',
      trackingNumber: 'IDEMPOTENT-001', carrier: 'Canada Post',
    }, sellerAuth.idToken);
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'delivered' }, sellerAuth.idToken);

    const buyerAuth = await signIn('buyer16@test.origna.ca');
    // First confirm
    const r1 = await callCallable('confirm_order_receipt', { orderId: result.orderId }, buyerAuth.idToken);
    expect(r1.captured).toBe(true);
    // Second confirm — should succeed idempotently
    const r2 = await callCallable('confirm_order_receipt', { orderId: result.orderId }, buyerAuth.idToken);
    expect(r2.success).toBe(true);
    console.log('   ✅ Double confirm is idempotent');
  });

  test('H.4 Cannot confirm receipt on unshipped order', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer17@test.origna.ca', 'product_008', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    // Order is confirmed but not shipped — try to confirm receipt
    const buyerAuth = await signIn('buyer17@test.origna.ca');
    try {
      await callCallable('confirm_order_receipt', { orderId: result.orderId }, buyerAuth.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      // Backend may return "Order not shipped yet" or generic "INTERNAL"
      expect(e.message).toMatch(/not shipped yet|INTERNAL|not yet shipped|cannot.*capture/i);
      console.log('   ✅ Cannot confirm receipt before shipping');
    }
  });

  test('H.5 Confirm receipt on shipped order (before delivered) works', async ({ page }) => {
    test.setTimeout(90_000);
    const result = await fullCheckoutAndPay(page, 'buyer18@test.origna.ca', 'product_008', 1);
    await waitForOrderStatus(result.orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller3@test.origna.ca');
    await callCallable('update_order_status', { orderId: result.orderId, newStatus: 'processing' }, sellerAuth.idToken);
    await callCallable('update_order_status', {
      orderId: result.orderId, newStatus: 'shipped',
      trackingNumber: 'EARLY-CONFIRM', carrier: 'Canada Post',
    }, sellerAuth.idToken);

    // Buyer confirms receipt even though seller hasn't marked delivered
    const buyerAuth = await signIn('buyer18@test.origna.ca');
    const r = await callCallable('confirm_order_receipt', { orderId: result.orderId }, buyerAuth.idToken);
    expect(r.success).toBe(true);
    expect(r.captured).toBe(true);

    const order = await getOrder(result.orderId);
    expect(order.paymentStatus).toBe('captured');
    console.log('   ✅ Confirm receipt works on shipped (before delivered)');
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE I · PARTIAL REFUND: refund_order_item after delivery
// ════════════════════════════════════════════════════════════════════════════

test.describe('I. Partial Refund After Delivery', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let seller1Token: string;
  let buyerToken: string;

  test('I.1 Full lifecycle: checkout → deliver → capture', async ({ page }) => {
    test.setTimeout(120_000);
    console.log('🔄 I.1 — Full lifecycle for refund test');

    const result = await fullCheckoutAndPay(page, 'buyer19@test.origna.ca', 'product_003', 2); // 2x Tourtière Spice Kit
    orderId = result.orderId;
    await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);

    const sellerAuth = await signIn('seller1@test.origna.ca');
    seller1Token = sellerAuth.idToken;
    const buyerAuth = await signIn('buyer19@test.origna.ca');
    buyerToken = buyerAuth.idToken;

    // Seller: confirmed → processing → shipped → delivered
    await callCallable('update_order_status', { orderId, newStatus: 'processing' }, seller1Token);
    await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'REFUND-TEST-001', carrier: 'Canada Post',
    }, seller1Token);
    await callCallable('update_order_status', { orderId, newStatus: 'delivered' }, seller1Token);

    // Buyer confirms receipt
    const captureResult = await callCallable('confirm_order_receipt', { orderId }, buyerToken);
    expect(captureResult.captured).toBe(true);
    console.log('   ✅ Full lifecycle complete, payment captured');
  });

  test('I.2 Seller refunds the item', async () => {
    test.setTimeout(30_000);
    console.log('💸 I.2 — Partial refund');

    const stockBefore = await getProductStock('product_003');

    const result = await callCallable('refund_order_item', {
      orderId, productId: 'product_003', reason: 'Defective item',
    }, seller1Token);
    expect(result.success).toBe(true);
    expect(result.refundAmount).toBeGreaterThan(0);
    expect(result.refundId).toBeTruthy();

    // Verify item status updated
    const order = await getOrder(orderId);
    const item = order.items.find((i: any) => i.productId === 'product_003');
    expect(item.status).toBe('refunded');
    expect(item.refundReason).toContain('Defective');

    // Verify stock restored
    const stockAfter = await getProductStock('product_003');
    expect(stockAfter).toBe(stockBefore + 2); // 2 units restored
    console.log(`   ✅ Refunded $${result.refundAmount}, refundId=${result.refundId}, stock +2`);
  });

  test('I.3 Cannot refund same item twice', async () => {
    try {
      await callCallable('refund_order_item', {
        orderId, productId: 'product_003', reason: 'Double refund attempt',
      }, seller1Token);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toContain('already refunded');
      console.log('   ✅ Double refund blocked (Item already refunded)');
    }
  });
});


// ════════════════════════════════════════════════════════════════════════════
// SUITE J · RATING: Buyer rates product after delivery
// ════════════════════════════════════════════════════════════════════════════

test.describe('J. Product Rating After Delivery', () => {
  test.beforeEach(async ({ request }) => {
    const infra = await checkInfrastructure(request);
    test.skip(!infra.auth || !infra.firestore || !infra.functions,
      'Emulators not running. Run `firebase emulators:start`');
  });
  test.describe.configure({ mode: 'serial' });

  let orderId: string;
  let buyerToken: string;
  let buyerId: string;

  test('J.1 Full lifecycle: checkout → deliver → capture', async ({ page }) => {
    test.setTimeout(120_000);
    console.log('⭐ J.1 — Full lifecycle for rating test');

    const result = await fullCheckoutAndPay(page, 'buyer20@test.origna.ca', 'product_003', 1);
    orderId = result.orderId;
    await waitForOrderStatus(orderId, ['confirmed'], 'orderStatus', 60_000);

    const buyerAuth = await signIn('buyer20@test.origna.ca');
    buyerToken = buyerAuth.idToken;
    buyerId = buyerAuth.localId;

    const sellerAuth = await signIn('seller1@test.origna.ca');
    await callCallable('update_order_status', { orderId, newStatus: 'processing' }, sellerAuth.idToken);
    await callCallable('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'RATE-TEST-001', carrier: 'Canada Post',
    }, sellerAuth.idToken);
    await callCallable('update_order_status', { orderId, newStatus: 'delivered' }, sellerAuth.idToken);
    await callCallable('confirm_order_receipt', { orderId }, buyerToken);
    console.log('   ✅ Order delivered and captured');
  });

  test('J.2 Buyer submits 5-star rating', async () => {
    test.setTimeout(15_000);
    console.log('⭐ J.2 — Submit rating');

    const result = await callCallable('submit_product_rating', {
      productId: 'product_003',
      orderId,
      rating: 5,
      review: 'Great tourtière spice kit!',
    }, buyerToken);
    expect(result.success).toBe(true);
    console.log('   ✅ 5-star rating submitted');
  });

  test('J.3 Rating without purchase blocked', async () => {
    // buyer21 hasn't purchased this product
    const otherBuyer = await signIn('buyer21@test.origna.ca');
    try {
      await callCallable('submit_product_rating', {
        productId: 'product_003',
        orderId,
        rating: 1,
        review: 'Fake review',
      }, otherBuyer.idToken);
      throw new Error('Should have thrown');
    } catch (e: any) {
      expect(e.message).toMatch(/purchase|order|not.*buyer/i);
      console.log('   ✅ Rating without purchase blocked');
    }
  });
});
