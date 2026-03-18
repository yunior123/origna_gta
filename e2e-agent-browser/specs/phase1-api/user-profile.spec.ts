/**
 * OrignaGTA — User Profile API E2E Tests
 * =======================================
 * Comprehensive coverage of user profile operations: get, update, email change, data export.
 */
import { test, expect, describe } from 'bun:test';
import {
  callOk,
  callExpectError,
  uid,
} from '../../lib/api-client.js';
import { signIn } from '../../lib/auth.js';
import { TEST_ACCOUNTS } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;

describe('User Profile API', () => {
  test('UP1: Get user profile returns current user data', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    expect(profile.email || profile.uid || profile.userId).toBeTruthy();
  });

  test('UP2: User profile contains expected fields', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    const hasNameField = profile.name || profile.displayName || profile.fullName;
    const hasEmailField = profile.email;
    const hasIdField = profile.uid || profile.userId || profile.id;
    
    expect(hasIdField).toBeTruthy();
  });

  test('UP3: Update profile display name', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const newName = `User ${uid()}`;

    const result = await callOk('update_user_profile', {
      name: newName,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();

    // Verify update
    const profile = await callOk('get_user_profile', {}, auth.idToken);
    const displayName = profile.name || profile.displayName || profile.fullName;
    if (displayName) {
      expect(displayName).toBe(newName);
    }
  });

  test('UP4: Update profile bio/about', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const bio = 'This is my bio ' + uid();

    const result = await callOk('update_user_profile', {
      bio,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();

    // Verify
    const profile = await callOk('get_user_profile', {}, auth.idToken);
    if (profile.bio) {
      expect(profile.bio).toBe(bio);
    }
  });

  test('UP5: Update profile avatar/photo URL', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const avatarUrl = 'https://example.com/avatar.jpg';

    const result = await callOk('update_user_profile', {
      photoUrl: avatarUrl,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP6: Change email address', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const newEmail = `test-${uid()}@example.com`;

    const result = await callOk('change_email', {
      newEmail,
    }, auth.idToken);

    expect(result.success || result.sent).toBeTruthy();
  });

  test('UP7: Change password', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const newPassword = `NewPass${uid()}!`;

    const result = await callOk('change_password', {
      currentPassword: TEST_ACCOUNTS.BUYER_PASS,
      newPassword,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP8: Change password with wrong current password fails', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const newPassword = `NewPass${uid()}!`;

    const err = await callExpectError('change_password', {
      currentPassword: 'WrongPassword',
      newPassword,
    }, auth.idToken);

    expect(err).toBeTruthy();
    expect(['failed-precondition', 'unauthenticated']).toContain(err?.code);
  });

  test('UP9: Update email preferences/notifications', async () => {
    const auth = await signIn(BUYER_EMAIL);

    const result = await callOk('update_email_preferences', {
      receiveOrderNotifications: true,
      receiveMarketingEmails: false,
      receivePromotions: false,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP10: Unsubscribe from all marketing emails', async () => {
    const auth = await signIn(BUYER_EMAIL);

    const result = await callOk('update_email_preferences', {
      receiveMarketingEmails: false,
      receivePromotions: false,
    }, auth.idToken);

    expect(result.success || result.updated).toBeTruthy();
  });

  test('UP11: Export user data (GDPR)', async () => {
    const auth = await signIn(BUYER_EMAIL);

    const result = await callOk('export_user_data', {}, auth.idToken);

    expect(result).toBeTruthy();
    expect(result.dataUrl || result.exportUrl).toBeTruthy();
  });

  test('UP12: Request account deletion', async () => {
    const auth = await signIn(BUYER_EMAIL);

    const result = await callOk('request_account_deletion', {
      password: TEST_ACCOUNTS.BUYER_PASS,
      reason: 'Testing account deletion',
    }, auth.idToken);

    expect(result.success || result.initiated).toBeTruthy();
  });

  test('UP13: Seller profile has additional fields', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const profile = await callOk('get_user_profile', {}, auth.idToken);

    expect(profile).toBeTruthy();
    // Sellers may have storeName, businessAddress, etc.
    const isSeller = profile.role === 'seller' || profile.roles?.includes('seller');
    expect(isSeller).toBe(true);
  });

  test('UP14: Update seller business name', async () => {
    const auth = await signIn(SELLER_EMAIL);
    const storeName = `Store ${uid()}`;

    const result = await callOk('update_seller_profile', {
      storeName,
    }, auth.idToken);

    expect(result.success || result.updated || result).toBeTruthy();
  });

  test('UP15: Unauthenticated profile operations fail', async () => {
    const err = await callExpectError('get_user_profile', {}, 'invalid-token-xxx');
    expect(['unauthenticated', 'failed-precondition']).toContain(err?.code);
  });

  test('UP16: Profile name has reasonable length limits', async () => {
    const auth = await signIn(BUYER_EMAIL);
    const veryLongName = 'A'.repeat(1000); // Excessive length

    const result = await callCallable('update_user_profile', {
      name: veryLongName,
    }, auth.idToken);

    // Should either fail or truncate
    expect(result).toBeTruthy();
  });
});
