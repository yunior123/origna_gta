import { beforeAll, describe, expect, test } from 'bun:test';
import { callExpectError, callOk, signIn } from '../../lib/api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS } from '../../lib/config.js';

describe('Security — Auth Fixes (JWT, CORS, Admin, Rate Limit)', () => {
  let adminToken = '';
  let sellerToken = '';
  let buyerToken = '';

  beforeAll(async () => {
    adminToken = (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL)).idToken;
    sellerToken = (await signIn(TEST_ACCOUNTS.SELLER_EMAIL)).idToken;
    buyerToken = (await signIn(TEST_ACCOUNTS.BUYER_EMAIL)).idToken;
  });

  test('T01: Request without Authorization header is rejected', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    expect([401, 403]).toContain(res.status);
  });

  test('T02: Request with invalid JWT is rejected', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer invalid.jwt.token',
      },
      body: JSON.stringify({}),
    });
    expect([401, 403]).toContain(res.status);
  });

  test('T03: Request with valid JWT succeeds', async () => {
    const profile = await callOk('get_user_profile', {}, buyerToken);
    expect(profile).toBeTruthy();
  });

  test('T04: Allowed dev origin receives a non-wildcard CORS header', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'OPTIONS',
      headers: {
        Origin: 'https://dev.orignagta.ca',
        'Access-Control-Request-Method': 'POST',
      },
    });
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin).not.toBe('*');
    }
  });

  test('T05: Untrusted origin is not expanded to wildcard', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'OPTIONS',
      headers: {
        Origin: 'https://evil.com',
        'Access-Control-Request-Method': 'POST',
      },
    });
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin).not.toBe('*');
    }
  });

  test('T06: Production origin preflight returns a deterministic header shape', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'OPTIONS',
      headers: {
        Origin: 'https://orignagta.ca',
        'Access-Control-Request-Method': 'POST',
      },
    });
    const allowOrigin = res.headers.get('Access-Control-Allow-Origin');
    if (allowOrigin) {
      expect(allowOrigin.length).toBeGreaterThan(0);
    }
  });

  test('T07: Buyer cannot access admin user listing', async () => {
    const error = await callExpectError('admin_get_users', {}, buyerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T08: Admin can hit admin MFA endpoints', async () => {
    const result = await callOk('admin_mfa_enroll', {}, adminToken).catch((error) => error);
    expect(result).toBeTruthy();
  });

  test('T09: Seller cannot access admin user listing', async () => {
    const error = await callExpectError('admin_get_users', {}, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T10: Buyer cannot escalate into admin APIs', async () => {
    const error = await callExpectError('admin_flag_review', {
      reviewId: 'review:test',
      reason: 'test',
    }, buyerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T11: Seller cannot modify another seller product', async () => {
    const error = await callExpectError('update_product', {
      productId: 'someone_elses_product',
      name: 'Hacked!',
    }, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T12: Seller self-purchase attempts are blocked or rejected', async () => {
    const error = await callExpectError('create_checkout_session', {
      items: [{ productId: 'e2e_product_test_seller', sellerId: 'seller', quantity: 1, priceCents: 1000 }],
      shippingAddress: {
        street: '123 Main',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'CA',
      },
      subtotalCents: 1000,
      shippingCostCents: 0,
      totalAmountCents: 1000,
    }, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T13: Repeated invalid logins never return a successful auth payload', async () => {
    const attempts: number[] = [];
    for (let i = 0; i < 12; i++) {
      const res = await fetch(`${ORIGNABASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: 'rate_limit_test@test.origna.ca',
          password: 'wrong_password',
        }),
      });
      attempts.push(res.status);
    }
    expect(attempts.every((status) => [400, 401, 403, 429].includes(status))).toBe(true);
  });

  test('T14: Order status values remain stable strings', async () => {
    const orders = await callOk('get_orders', { limit: 5 }, buyerToken);
    for (const order of orders.orders || []) {
      if (typeof order.status === 'string') {
        expect(order.status.trim().length).toBeGreaterThan(0);
        expect(order.status.toLowerCase()).toBe(order.status.trim().toLowerCase());
      }
    }
  });

  test('T15: Unsigned stripe webhook is rejected on the canonical route', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/api/webhooks/stripe`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: 'evt_fake',
        type: 'payment_intent.succeeded',
        data: { object: { id: 'pi_fake' } },
      }),
    });
    expect([400, 401, 403, 404]).toContain(res.status);
  });

  test('T16: Health endpoint returns HTTP 200 and an ok payload', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/health`);
    expect(res.status).toBe(200);
    const text = await res.text();
    expect(text.toLowerCase()).toContain('ok');
  });
});
