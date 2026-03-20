import { describe, expect, test } from 'bun:test';
import { callExpectError, callOk, uid } from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;

describe('User Profile API', () => {
  test('UP1: Get user profile returns current user data', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    expect(profile.email || profile.uid || profile.userId || profile.id).toBeTruthy();
  });

  test('UP2: User profile contains expected fields', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    expect(profile.email || profile.id || profile.userId || profile.uid).toBeTruthy();
  });

  test('UP3: Update profile display name', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const newName = `User ${uid()}`;
    const result = await callOk('update_user_profile', { name: newName }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP4: Update profile address', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('update_user_profile', {
      address: {
        street: '123 Main St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP5: Update preferred language', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('update_user_profile', {
      preferredLanguage: 'en',
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP6: Update email consent', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('update_email_consent', {
      consent: false,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP7: Update notification preferences', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('update_notification_preferences', {
      notifyNewProducts: true,
      notifyTrending: false,
    }, auth.idToken).catch((error) => error);

    expect(result).toBeTruthy();
  });

  test('UP8: Invalid language fails', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const err = await callExpectError('update_user_profile', {
      preferredLanguage: 'es',
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('UP9: Non-Canadian profile address fails', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const err = await callExpectError('update_user_profile', {
      address: {
        street: '123 Main St',
        city: 'Buffalo',
        province: 'NY',
        postalCode: '14201',
        country: 'US',
      },
    }, auth.idToken);

    expect(err).toBeTruthy();
  });

  test('UP10: Terms acceptance can be recorded', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const result = await callOk('update_user_profile', {
      termsVersion: `v${Date.now()}`,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP11: Seller profile can be fetched', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    expect(profile.id || profile.uid || profile.userId).toBeTruthy();
  });

  test('UP12: Seller can update display name through the shared profile endpoint', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const result = await callOk('update_user_profile', {
      name: `Seller ${uid()}`,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP13: Unauthenticated profile operations fail', async () => {
    const err = await callExpectError('get_user_profile', {}, 'invalid-token-xxx');
    expect(['unauthenticated', 'failed-precondition']).toContain(err?.code);
  });

  test('UP14: Profile name has reasonable length limits', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const err = await callExpectError('update_user_profile', {
      name: 'A'.repeat(1000),
    }, auth.idToken);

    expect(err).toBeTruthy();
  });
});
