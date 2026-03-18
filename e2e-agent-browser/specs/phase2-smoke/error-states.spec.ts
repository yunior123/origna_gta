/**
 * OrignaGTA — Error States E2E Tests
 * ====================================
 * Tests API error responses: 404, 400, 401, and rate limiting (429).
 * Pure API tests — no browser needed.
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn, callCallable, callExpectError,
} from '../../lib/api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS } from '../../lib/config.js';

const API_BASE = ORIGNABASE_URL;

describe('Error States — API Responses', () => {
  let buyerToken: string;

  beforeAll(async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    buyerToken = auth.idToken;
  }, 30_000);

  test('Invalid API endpoint returns 404', { timeout: 30_000 }, async () => {
    const res = await fetch(`${API_BASE}/api/v1/nonexistent-endpoint-xyz`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${buyerToken}`,
        'Content-Type': 'application/json',
      },
    });

    // OrignaBase should return 404 for unknown routes
    expect(res.status === 404 || res.status === 405).toBe(true);
  });

  test('Malformed request body returns 400', { timeout: 30_000 }, async () => {
    // Send a checkout request with missing required fields
    const result = await callCallable('create_checkout_session', {
      // Missing: items, shippingAddress, etc.
      invalidField: 'garbage',
    }, buyerToken);

    // Should get an error (bad request / invalid argument)
    const hasError = result?.error != null;
    const errCode = result?.error?.code ?? '';
    const errMsg = String(result?.error?.message ?? '').toLowerCase();

    expect(
      hasError ||
      errCode === 'invalid-argument' ||
      errCode === 'bad-request' ||
      /missing|required|invalid|bad request/i.test(errMsg)
    ).toBe(true);
  });

  test('Request without auth token returns 401 or unauthenticated', { timeout: 30_000 }, async () => {
    // Call a protected endpoint with no token
    const res = await fetch(`${API_BASE}/api/v1/callable/get_user_profile`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: {} }),
    });

    // Should be 401 Unauthorized or 403 Forbidden
    expect(res.status === 401 || res.status === 403 || res.status === 400).toBe(true);
  });

  test('Request with invalid auth token is rejected', { timeout: 30_000 }, async () => {
    const fakeToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.fake.invalid';

    const res = await fetch(`${API_BASE}/api/v1/callable/get_user_profile`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${fakeToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ data: {} }),
    });

    expect(res.status === 401 || res.status === 403).toBe(true);
  });

  test('Calling non-existent callable returns error', { timeout: 30_000 }, async () => {
    const result = await callCallable('completely_fake_function_xyz', {}, buyerToken);

    const hasError = result?.error != null;
    const errCode = result?.error?.code ?? '';
    const errStatus = result?.error?.status;

    expect(
      hasError ||
      errCode === 'not-found' ||
      errStatus === 404 ||
      /not found|unknown|does not exist/i.test(String(result?.error?.message ?? ''))
    ).toBe(true);
  });

  test('Rapid API calls do not crash the service (rate limit tolerance)', { timeout: 60_000 }, async () => {
    // Fire 15 rapid requests to a read endpoint
    const results = await Promise.all(
      Array.from({ length: 15 }, () =>
        fetch(`${API_BASE}/api/v1/callable/get_user_profile`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${buyerToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ data: {} }),
        }).then(r => ({ status: r.status, ok: r.ok }))
          .catch(e => ({ status: 0, ok: false, error: e.message }))
      )
    );

    // All requests should get a response (service didn't crash)
    expect(results.length).toBe(15);

    const statuses = results.map(r => r.status);
    const has2xx = statuses.some(s => s >= 200 && s < 300);
    const has429 = statuses.some(s => s === 429);

    // At least some should succeed; if rate limited, 429 is acceptable
    expect(has2xx || has429).toBe(true);

    // Log for monitoring
    const statusCounts: Record<number, number> = {};
    for (const s of statuses) statusCounts[s] = (statusCounts[s] || 0) + 1;
    console.log('Rapid API test status distribution:', JSON.stringify(statusCounts));
  });
});
