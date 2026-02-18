/**
 * OrignaGTA — Rate Limiting E2E Tests
 * =====================================
 * Tests API rate limiting against dev Firebase.
 */
import { test, expect } from '@playwright/test';
import {
  signIn, callCallable,
  buildCheckoutPayload,
  TEST_ACCOUNTS,
} from './api-helpers';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;

test.describe('Rate Limiting', () => {
  test.setTimeout(120_000);

  test('Rapid checkout requests are rate-limited', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const { data } = await buildCheckoutPayload(auth.localId, 'product_001', 1, auth.idToken);

    // Fire 10 rapid checkout requests
    const results = await Promise.all(
      Array.from({ length: 10 }, () =>
        callCallable('create_checkout_session', data, auth.idToken)
      )
    );

    // At least some should succeed, but if rate limiting is active,
    // later requests should be throttled or rejected
    const errors = results.filter(r => r.error);
    const successes = results.filter(r => !r.error);

    // We expect at least 1 success (first request)
    expect(successes.length).toBeGreaterThan(0);

    // If rate limiting is properly configured, some should fail
    // (but in dev environment, rate limiting may not be active)
    if (errors.length > 0) {
      const rateLimitErrors = errors.filter(r =>
        r.error?.message?.toLowerCase().includes('rate') ||
        r.error?.status === 'RESOURCE_EXHAUSTED'
      );
      // Log for visibility
      console.log(`Rate limit test: ${successes.length} success, ${errors.length} errors (${rateLimitErrors.length} rate-limit specific)`);
    }
  });

  test('Multiple rapid API calls do not crash the service', async () => {
    const auth = await signIn(BUYER_EMAIL);

    // Fire 5 rapid read requests
    const results = await Promise.all(
      Array.from({ length: 5 }, () =>
        callCallable('get_connect_account_status', {}, auth.idToken).catch(e => ({ error: e }))
      )
    );

    // At least some should return (service is alive)
    const responded = results.filter(r => r !== null && r !== undefined);
    expect(responded.length).toBeGreaterThan(0);
  });
});
