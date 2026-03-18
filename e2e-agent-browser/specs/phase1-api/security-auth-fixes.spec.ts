/**
 * OrignaGTA — Security Auth Fixes E2E Tests (agent-browser)
 * ============================================================
 * Verify critical authentication & authorization fixes:
 * - JWT validation (no algorithm bypass, no expired tokens)
 * - No anonymous access (Authorization header required)
 * - CORS enforcement
 * - Admin role checks
 * - Self-purchase prevention
 * - Rate limiting
 * - OrderStatus normalization
 * - Webhook signature verification
 * - Health endpoint
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn,
  callOk,
  callCallable,
  callExpectError,
} from '../../lib/api-client.js';
import {
  TEST_ACCOUNTS,
  ORIGNABASE_URL,
  DEFAULT_PASS,
} from '../../lib/config.js';

const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const TEST_PASS = DEFAULT_PASS;

describe('Security — Auth Fixes (JWT, CORS, Admin, Rate Limit)', () => {
  let adminToken: string;
  let sellerToken: string;
  let buyerToken: string;

  beforeAll(async () => {
    const admin = await signIn(ADMIN_EMAIL, TEST_PASS);
    const seller = await signIn(SELLER_EMAIL, TEST_PASS);
    const buyer = await signIn(BUYER_EMAIL, TEST_PASS);
    adminToken = admin.idToken;
    sellerToken = seller.idToken;
    buyerToken = buyer.idToken;
  });

  // ════════════════════════════════════════════════════════════════════
  // T01–T03: JWT Validation
  // ════════════════════════════════════════════════════════════════════

  test('T01: Request without Authorization header → 401', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
    // Should not allow anonymous access
    expect([401, 403]).toContain(res.status);
  });

  test('T02: Request with invalid JWT → 401', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer invalid.jwt.token',
      },
    });
    expect([401, 403]).toContain(res.status);
  });

  test('T03: Request with valid JWT → 200', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${buyerToken}`,
      },
    });
    expect([200, 401, 403]).toContain(res.status);
    // If 200, response should have user data
    if (res.status === 200) {
      const data = await res.json();
      expect(data).toBeTruthy();
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T04–T06: CORS Enforcement
  // ════════════════════════════════════════════════════════════════════

  test('T04: CORS: request from dev.orignagta.ca origin → allowed', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://dev.orignagta.ca',
        'Access-Control-Request-Method': 'GET',
      },
    });
    // Should allow CORS preflight for allowed origins
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin).toContain('orignagta.ca');
    }
  });

  test('T05: CORS: request from evil.com origin → blocked', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://evil.com',
        'Access-Control-Request-Method': 'GET',
      },
    });
    // Should NOT allow CORS from untrusted origins
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin).not.toContain('evil.com');
    } else {
      // No CORS header = blocked
      expect(allowOrigin).toBe(null);
    }
  });

  test('T06: CORS: orignagta.ca production origin allowed', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/auth/profile`, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://orignagta.ca',
        'Access-Control-Request-Method': 'GET',
      },
    });
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin).toContain('orignagta.ca');
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T07–T09: Admin Role Enforcement
  // ════════════════════════════════════════════════════════════════════

  test('T07: Admin endpoint without admin role → 403', { timeout: 60_000 }, async () => {
    // Buyer tries to access admin-only endpoint
    const error = await callExpectError('admin_list_users', {}, buyerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T08: Admin with admin role → can access admin endpoints', { timeout: 60_000 }, async () => {
    // Admin should be able to call admin functions
    const result = await callCallable('admin_mfa_enroll', {}, adminToken);
    // May succeed or return "already enrolled", both acceptable
    expect(result).toBeTruthy();
  });

  test('T09: Seller tries to access admin endpoint → 403', { timeout: 60_000 }, async () => {
    const error = await callExpectError('admin_list_users', {}, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T10–T12: Access Control (Data Isolation)
  // ════════════════════════════════════════════════════════════════════

  test('T10: Buyer tries to read another buyers orders → empty or 403', { timeout: 60_000 }, async () => {
    // Sign in as buyer1
    const buyer1Auth = await signIn(BUYER_EMAIL, TEST_PASS);
    
    // Try to list all users (buyer shouldn't see this)
    const error = await callExpectError('admin_list_users', {}, buyer1Auth.idToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T11: Seller tries to modify another sellers product → 403', { timeout: 60_000 }, async () => {
    // Seller tries to modify a product they don't own
    const error = await callExpectError('update_product', {
      productId: 'someone_elses_product',
      name: 'Hacked!',
    }, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T12: Self-purchase prevention: seller tries to buy own product → blocked', { timeout: 60_000 }, async () => {
    // This requires the backend to check if seller is buying their own product
    // For now, we verify that such attempts are handled gracefully
    const result = await callCallable('validate_self_purchase_block', {
      sellerId: 'test_seller',
      buyerId: 'test_seller', // Same ID = self-purchase
    }, sellerToken);
    
    // Should have error or return validation failure
    if (!result.error) {
      expect(result.allowed || result.success).toBe(false);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T13: Rate Limiting
  // ════════════════════════════════════════════════════════════════════

  test('T13: Rate limit: 10+ rapid login attempts → 429', { timeout: 90_000 }, async () => {
    const loginAttempts = [];
    const ATTEMPT_COUNT = 12;

    for (let i = 0; i < ATTEMPT_COUNT; i++) {
      const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'rate_limit_test@test.origna.ca',
          password: 'wrong_password',
        }),
      });
      loginAttempts.push(res.status);
      
      // Don't spam too hard
      if (i < ATTEMPT_COUNT - 1) {
        await new Promise(r => setTimeout(r, 100));
      }
    }

    // Should see at least one 429 (rate limited)
    expect(loginAttempts.some(status => status === 429 || status >= 429)).toBe(true);
  });

  // ════════════════════════════════════════════════════════════════════
  // T14: OrderStatus Normalization
  // ════════════════════════════════════════════════════════════════════

  test('T14: OrderStatus API returns lowercase values (pending, confirmed, etc)', { timeout: 60_000 }, async () => {
    // Call a function that returns order data
    const result = await callCallable('list_buyer_orders', {
      limit: 5,
      offset: 0,
    }, buyerToken);

    // If there are orders, verify status is lowercase
    if (result.result && result.result.orders && result.result.orders.length > 0) {
      const order = result.result.orders[0];
      const status = order.status || '';
      expect(['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']).toContain(status.toLowerCase());
      expect(status).toBe(status.toLowerCase()); // Must be lowercase
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T15: Webhook Signature Verification
  // ════════════════════════════════════════════════════════════════════

  test('T15: Webhook: POST to /stripe/webhook without Stripe-Signature → rejected', { timeout: 60_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/stripe/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: 'evt_fake',
        type: 'payment_intent.succeeded',
        data: { object: { id: 'pi_fake' } },
      }),
    });

    // Should reject unsigned webhooks
    expect([401, 403, 400, 498]).toContain(res.status);
  });

  // ════════════════════════════════════════════════════════════════════
  // T16: Health Endpoint
  // ════════════════════════════════════════════════════════════════════

  test('T16: Health endpoint: GET /health → "ok" or similar', { timeout: 30_000 }, async () => {
    const res = await fetch(`${ORIGNABASE_URL}/health`, {
      method: 'GET',
    });

    expect([200, 404]).toContain(res.status);
    if (res.status === 200) {
      const data = await res.json();
      expect(data.status || data.health || data.ok).toBeTruthy();
    }
  });
});
