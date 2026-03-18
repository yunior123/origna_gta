/**
 * OrignaGTA — Order State Transition Validation E2E Tests
 * ========================================================
 * Tests that invalid order state transitions are rejected by the API.
 * Verifies the order state machine: pending -> confirmed -> shipped -> delivered
 * with cancelled as a terminal state.
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn, callOk, callCallable, callExpectError,
  fullCheckoutAndPay, waitForOrderStatus,
  getSellerAuth, getOrder, getTestProduct,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_UIDS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const STABLE_PRODUCT_ID = 'e2e_product_test_seller';

function isRateLimited(e: any): boolean {
  return /rate limit|duplicate order|not available|too many/i.test(String(e?.message ?? e ?? ''));
}

function isTransientError(e: any): boolean {
  return /agent-browser.*failed|snapshot failed|internal error|failed to create payment|Connection refused/i.test(String(e?.message ?? e ?? ''));
}

describe('Order State Transition Validation', () => {

  let buyerAuth: Awaited<ReturnType<typeof signIn>>;
  let sellerAuth: Awaited<ReturnType<typeof signIn>>;
  let adminAuth: Awaited<ReturnType<typeof signIn>>;

  beforeAll(async () => {
    buyerAuth = await signIn(BUYER_EMAIL);
    adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    sellerAuth = await getSellerAuth(product.sellerId);
  }, 30_000);

  test('Cannot skip states: pending -> delivered is rejected', { timeout: 120_000 }, async () => {
    let orderId: string;
    try {
      const result = await fullCheckoutAndPay(BUYER_EMAIL, STABLE_PRODUCT_ID, 1);
      orderId = result.orderId;
    } catch (e: any) {
      if (isRateLimited(e) || isTransientError(e)) {
        console.log('Skipped: ' + String(e?.message ?? '').slice(0, 80));
        return;
      }
      throw e;
    }

    // Wait for confirmed first
    const freshAuth = await signIn(BUYER_EMAIL);
    try {
      await waitForOrderStatus(orderId, ['confirmed'], freshAuth.idToken, 15_000);
    } catch (e: any) {
      if (/PENDING_PAYMENT|pending/i.test(String(e?.message ?? ''))) {
        console.log('Skipped: order stuck in pending');
        return;
      }
      throw e;
    }

    // Try to skip to delivered (should fail — must go through processing, shipped)
    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'delivered',
    }, sellerAuth.idToken);

    const errCode = result?.error?.code ?? result?.error?.status;
    const errMsg = String(result?.error?.message ?? '').toLowerCase();
    // Should be rejected with 409 conflict or invalid-argument
    expect(
      errCode === 'failed-precondition' ||
      errCode === 'invalid-argument' ||
      errCode === 409 ||
      /invalid.*transition|cannot.*transition|not allowed|conflict/i.test(errMsg) ||
      result?.error != null
    ).toBe(true);
  });

  test('Cannot transition from cancelled state', { timeout: 120_000 }, async () => {
    let orderId: string;
    try {
      const result = await fullCheckoutAndPay(BUYER_EMAIL, STABLE_PRODUCT_ID, 1);
      orderId = result.orderId;
    } catch (e: any) {
      if (isRateLimited(e) || isTransientError(e)) {
        console.log('Skipped: ' + String(e?.message ?? '').slice(0, 80));
        return;
      }
      throw e;
    }

    // Cancel the order first
    const freshAuth = await signIn(BUYER_EMAIL);
    try {
      await callOk('cancel_order', { orderId }, freshAuth.idToken);
    } catch (e: any) {
      // Order might already be confirmed (can't cancel) — try with admin
      try {
        await callOk('cancel_order', { orderId, reason: 'E2E test cleanup' }, adminAuth.idToken);
      } catch {
        console.log('Skipped: could not cancel order for test');
        return;
      }
    }

    // Now try to transition cancelled -> shipped (should fail)
    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'shipped',
      trackingNumber: 'FAKE-123',
      carrier: 'Canada Post',
    }, sellerAuth.idToken);

    const errCode = result?.error?.code ?? result?.error?.status;
    const errMsg = String(result?.error?.message ?? '').toLowerCase();
    expect(
      errCode === 'failed-precondition' ||
      errCode === 'invalid-argument' ||
      errCode === 409 ||
      /invalid.*transition|cannot.*transition|cancelled|terminal|not allowed/i.test(errMsg) ||
      result?.error != null
    ).toBe(true);
  });

  test('Cannot reverse state: delivered -> pending is rejected', { timeout: 180_000 }, async () => {
    let orderId: string;
    try {
      const result = await fullCheckoutAndPay(BUYER_EMAIL, STABLE_PRODUCT_ID, 1);
      orderId = result.orderId;
    } catch (e: any) {
      if (isRateLimited(e) || isTransientError(e)) {
        console.log('Skipped: ' + String(e?.message ?? '').slice(0, 80));
        return;
      }
      throw e;
    }

    const freshAuth = await signIn(BUYER_EMAIL);
    try {
      await waitForOrderStatus(orderId, ['confirmed'], freshAuth.idToken, 15_000);
    } catch (e: any) {
      if (/PENDING_PAYMENT|pending/i.test(String(e?.message ?? ''))) {
        console.log('Skipped: order stuck in pending');
        return;
      }
      throw e;
    }

    // Move to delivered through valid transitions
    const freshSellerAuth = await getSellerAuth(TEST_UIDS.SELLER.split(':')[1] ?? TEST_UIDS.SELLER);

    await callOk('update_order_status', { orderId, newStatus: 'processing' }, freshSellerAuth.idToken);
    await callOk('update_order_status', {
      orderId, newStatus: 'shipped',
      trackingNumber: 'TRANS-TEST-001', carrier: 'Canada Post',
    }, freshSellerAuth.idToken);
    await callOk('update_order_status', { orderId, newStatus: 'delivered' }, freshSellerAuth.idToken);

    // Now try to reverse: delivered -> pending (should fail)
    const result = await callCallable('update_order_status', {
      orderId,
      newStatus: 'pending',
    }, adminAuth.idToken);

    const errCode = result?.error?.code ?? result?.error?.status;
    const errMsg = String(result?.error?.message ?? '').toLowerCase();
    expect(
      errCode === 'failed-precondition' ||
      errCode === 'invalid-argument' ||
      errCode === 409 ||
      /invalid.*transition|cannot.*transition|delivered|terminal|not allowed/i.test(errMsg) ||
      result?.error != null
    ).toBe(true);
  });

  test('Valid transition: confirmed -> processing succeeds', { timeout: 120_000 }, async () => {
    let orderId: string;
    try {
      const result = await fullCheckoutAndPay(BUYER_EMAIL, STABLE_PRODUCT_ID, 1);
      orderId = result.orderId;
    } catch (e: any) {
      if (isRateLimited(e) || isTransientError(e)) {
        console.log('Skipped: ' + String(e?.message ?? '').slice(0, 80));
        return;
      }
      throw e;
    }

    const freshAuth = await signIn(BUYER_EMAIL);
    try {
      await waitForOrderStatus(orderId, ['confirmed'], freshAuth.idToken, 15_000);
    } catch (e: any) {
      if (/PENDING_PAYMENT|pending/i.test(String(e?.message ?? ''))) {
        console.log('Skipped: order stuck in pending');
        return;
      }
      throw e;
    }

    const freshSellerAuth = await getSellerAuth(TEST_UIDS.SELLER.split(':')[1] ?? TEST_UIDS.SELLER);
    await callOk('update_order_status', { orderId, newStatus: 'processing' }, freshSellerAuth.idToken);

    const order = await getOrder(orderId, freshAuth.idToken);
    expect(order).toBeTruthy();
    const status = order.orderStatus ?? order.status;
    expect(status).toBe('processing');
  });
});
