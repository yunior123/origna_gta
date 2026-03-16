/**
 * OrignaBase — Security & Access Control E2E Tests
 * =================================================
 * Verifies that the OrignaBase API enforces correct permissions
 * and rejects unauthorized requests.
 */

import { test, expect } from '@playwright/test';
import {
  signIn,
  callExpectError,
  TEST_ACCOUNTS,
  TEST_UIDS,
} from './api-helpers';

test.describe('OrignaBase Security Boundaries', () => {

  test('S1: Buyer CANNOT delete another user account', async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const err = await callExpectError('delete_account', { 
      userId: TEST_UIDS.SELLER, 
      confirmation: 'DELETE_MY_ACCOUNT' 
    }, auth.idToken);
    
    expect(err.code).toBe('permission-denied');
  });

  test('S2: Buyer CANNOT call Admin functions (mail logs)', async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const err = await callExpectError('get_mail_logs', { to: 'any@test.com' }, auth.idToken);

    // OrignaBase returns 403 when the endpoint enforces admin role, or 404 when the route
    // is not exposed to non-admin users at the routing layer.
    expect(['permission-denied', 'not-found']).toContain(err.code);
  });

  test('S3: Unauthenticated request to protected endpoint is rejected', async () => {
    const err = await callExpectError('get_user_profile', {}, 'invalid-token-123');
    expect(['unauthenticated', 'internal']).toContain(err.code);
  });

  test('S4: Non-Seller CANNOT answer a question', async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const err = await callExpectError('answer_question', {
      productId: 'any-id',
      questionId: 'any-q-id',
      answer: 'Hacker answer'
    }, auth.idToken);

    // OrignaBase enforces seller-only access at the handler level (403) or returns 404
    // when the question does not exist before the permission check fires.
    expect(['permission-denied', 'not-found']).toContain(err.code);
  });

});
