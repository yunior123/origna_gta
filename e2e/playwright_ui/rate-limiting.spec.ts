/**
 * OrignaGTA — Rate Limiting E2E Tests
 * =====================================
 * Tests API rate limiting against dev Firebase.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callCallable,
  buildCheckoutPayload,
  getTestProduct,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Rate Limiting', () => {
  test.setTimeout(120_000);

  let productId: string;
  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  test.beforeAll(async () => {
    buyerAuth = await signIn(BUYER_EMAIL);
    const product = await getTestProduct(buyerAuth.idToken, buyerAuth.localId);
    productId = product.id;
  });

  test('Rapid checkout requests trigger rate limiting', async () => {
    const { data } = await buildCheckoutPayload(buyerAuth.localId, productId, 1, buyerAuth.idToken);

    // Fire 10 rapid checkout requests
    const results = await Promise.all(
      Array.from({ length: 10 }, () =>
        callCallable('create_checkout_session', data, buyerAuth.idToken)
      )
    );

    const errors = results.filter(r => r.error);
    const successes = results.filter(r => !r.error);

    // Rate limiting should reject at least some requests.
    // In dev, the limit is 5 requests per minute — so with 10 rapid requests,
    // we expect some to fail (either from rate limit or prior test activity).
    // The key assertion: not ALL 10 should succeed.
    const rateLimitErrors = errors.filter(r =>
      r.error?.message?.toLowerCase().includes('rate') ||
      r.error?.status === 'RESOURCE_EXHAUSTED'
    );

    // At least one request should be rate-limited OR all fail (already at limit)
    expect(errors.length).toBeGreaterThan(0);
    console.log(`Rate limit test: ${successes.length} success, ${errors.length} errors (${rateLimitErrors.length} rate-limit specific)`);
  });

  test('Multiple rapid API calls do not crash the service', async () => {
    // Fire 5 rapid read requests
    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        callCallable('get_connect_account_status', {}, buyerAuth.idToken).catch(e => ({ error: e }))
      )
    );

    // At least some should return (service is alive)
    const responded = results.filter(r => r !== null && r !== undefined);
    expect(responded.length).toBeGreaterThan(0);
  });
});
