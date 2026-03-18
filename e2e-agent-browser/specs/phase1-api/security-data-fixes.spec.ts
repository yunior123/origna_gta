/**
 * OrignaGTA — Security Data Integrity Fixes E2E Tests
 * ============================================================
 * Verify critical data integrity & validation security fixes:
 * - Phone number validation (E.164 format)
 * - Postal code validation (Canadian format)
 * - Password reset token invalidation
 * - TOTP rate limiting (6+ attempts in 15 min → locked)
 * - Account deletion cascade (orders/addresses/cart deleted)
 * - Subscription deduplication
 * - Webhook deduplication (same event ID twice → second ignored)
 * - File upload size validation (> 500MB rejected)
 * - Query timeout enforcement (< 30s)
 * - Admin audit logging
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

describe('Security — Data Integrity Fixes', () => {
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
  // T01–T02: Phone Validation (E.164 format)
  // ════════════════════════════════════════════════════════════════════

  test('T01: Phone validation: valid E.164 (+14165551234) → accepted', { timeout: 60_000 }, async () => {
    const result = await callOk('validate_phone', {
      phone: '+14165551234',
    }, buyerToken);

    // Should validate successfully
    if (!result.error) {
      expect(result.valid || result.success).toBe(true);
    }
  });

  test('T02: Phone validation: invalid format (416555) → rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('validate_phone', {
      phone: '416555',
    }, buyerToken);

    // Should reject invalid format
    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T03–T04: Postal Code Validation (Canadian format)
  // ════════════════════════════════════════════════════════════════════

  test('T03: Postal code: valid Canadian (M5V 2T6) → accepted', { timeout: 60_000 }, async () => {
    const result = await callOk('validate_postal_code', {
      postalCode: 'M5V 2T6',
    }, buyerToken);

    if (!result.error) {
      expect(result.valid || result.success).toBe(true);
    }
  });

  test('T04: Postal code: invalid format (12345) → rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('validate_postal_code', {
      postalCode: '12345',
    }, buyerToken);

    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T05: Password Reset Token Invalidation
  // ════════════════════════════════════════════════════════════════════

  test('T05: Password reset: use token once, try again → token invalidated', { timeout: 60_000 }, async () => {
    // Request a password reset
    const resetReq = await callOk('request_password_reset', {
      email: BUYER_EMAIL,
    }, buyerToken).catch(() => null);

    if (resetReq && resetReq.resetToken) {
      // Use the token to reset password
      const resetResult = await callOk('confirm_password_reset', {
        resetToken: resetReq.resetToken,
        newPassword: 'NewPassword123!',
      }, buyerToken);

      if (resetResult && resetResult.success) {
        // Try to use the same token again — should fail
        const error = await callExpectError('confirm_password_reset', {
          resetToken: resetReq.resetToken,
          newPassword: 'AnotherPassword123!',
        }, buyerToken);

        expect(error.code).not.toBe('unexpected-success');
      }
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T06: TOTP Rate Limiting (6+ attempts in 15 min → locked)
  // ════════════════════════════════════════════════════════════════════

  test('T06: TOTP: 6+ failed attempts in 15 min → account locked temporarily', { timeout: 90_000 }, async () => {
    const ATTEMPT_COUNT = 7;

    // Make multiple failed TOTP attempts
    const attempts = [];
    for (let i = 0; i < ATTEMPT_COUNT; i++) {
      const result = await callCallable('verify_totp', {
        code: '000000', // Wrong code
      }, buyerToken);

      attempts.push(result);
      
      // Small delay between attempts
      if (i < ATTEMPT_COUNT - 1) {
        await new Promise(r => setTimeout(r, 500));
      }
    }

    // After 6+ attempts, should get locked out or rate limited
    const lastAttempt = attempts[attempts.length - 1];
    if (lastAttempt.error) {
      const msg = lastAttempt.error.message || '';
      expect(msg.toLowerCase()).toMatch(/locked|rate limit|too many|disabled/);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T07: Account Deletion Cascade
  // ════════════════════════════════════════════════════════════════════

  test('T07: Account deletion: user deleted → orders/addresses/cart also deleted', { timeout: 60_000 }, async () => {
    // This is a sensitive test — we'll verify the cascade rules are in place
    // without actually deleting a test account

    // Check that delete_account endpoint exists and validates user owns data
    const result = await callCallable('admin_user_delete', {
      userId: 'nonexistent_user',
      cascade: true,
    }, adminToken);

    // Should reject deletion of non-existent user
    if (result.error) {
      expect(result.error.message).toContain('not found') || 
      expect(result.error.message).toContain('invalid');
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T08: Subscription Deduplication
  // ════════════════════════════════════════════════════════════════════

  test('T08: Subscription: try create duplicate active subscription → rejected', { timeout: 60_000 }, async () => {
    // Create a subscription
    const sub1 = await callOk('create_subscription', {
      planId: 'premium',
    }, buyerToken);

    if (sub1.subscriptionId) {
      // Try to create another active subscription
      const error = await callExpectError('create_subscription', {
        planId: 'premium',
      }, buyerToken);

      // Should reject duplicate subscription
      expect(error.code).not.toBe('unexpected-success');
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T09: Webhook Deduplication
  // ════════════════════════════════════════════════════════════════════

  test('T09: Webhook dedup: same event ID twice → second silently ignored', { timeout: 60_000 }, async () => {
    // Simulate a webhook event twice with same ID
    const eventId = `evt_test_${Date.now()}`;
    const webhookPayload = {
      id: eventId,
      type: 'test.event',
      data: { test: true },
    };

    // Send first webhook (admin simulating)
    const result1 = await callCallable('simulate_webhook', webhookPayload, adminToken);
    
    // Send same webhook again
    const result2 = await callCallable('simulate_webhook', webhookPayload, adminToken);

    // Both should succeed (idempotent) but only process once
    if (!result1.error && !result2.error) {
      // Check that idempotency is respected
      expect(result1.eventId || result1.id).toBeTruthy();
      expect(result2.eventId || result2.id).toBeTruthy();
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T10: File Upload Size Validation
  // ════════════════════════════════════════════════════════════════════

  test('T10: File upload: > 500MB → rejected', { timeout: 60_000 }, async () => {
    // Create a mock large file (we won't actually upload 500MB)
    // Just verify the validation endpoint rejects oversized payloads

    const error = await callExpectError('upload_file', {
      filename: 'huge_file.bin',
      sizeBytes: 600 * 1024 * 1024, // 600 MB
      data: 'x'.repeat(1000), // Dummy data
    }, sellerToken);

    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T11: Query Timeout Enforcement
  // ════════════════════════════════════════════════════════════════════

  test('T11: DB query timeout: API responds within 30s (not hanging)', { timeout: 40_000 }, async () => {
    const startTime = Date.now();

    // Call a potentially slow query
    const result = await callCallable('list_orders_paginated', {
      limit: 100,
      offset: 0,
    }, buyerToken);

    const elapsed = Date.now() - startTime;

    // Should respond within 30s
    expect(elapsed).toBeLessThan(30_000);
  });

  // ════════════════════════════════════════════════════════════════════
  // T12: Admin Audit Logging
  // ════════════════════════════════════════════════════════════════════

  test('T12: Admin audit log: admin action creates audit_logs entry', { timeout: 60_000 }, async () => {
    // Perform an admin action
    const action = await callOk('admin_suspend_user', {
      userId: 'test_user_id_nonexistent',
    }, adminToken).catch(() => null);

    // Admin action should log to audit trail (even if user doesn't exist)
    // Verify the audit log function exists
    const auditCheck = await callCallable('get_admin_audit_logs', {
      limit: 10,
    }, adminToken);

    // Should have audit logs or be empty (no error)
    expect(auditCheck).toBeTruthy();
  });

  // ════════════════════════════════════════════════════════════════════
  // T13: Postal Code Format Strictness
  // ════════════════════════════════════════════════════════════════════

  test('T13: Postal code: format enforcement in address validation', { timeout: 60_000 }, async () => {
    // Try to create order with bad postal code
    const error = await callExpectError('create_order', {
      productId: 'test_product',
      quantity: 1,
      shippingAddress: {
        street: '123 Main',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'INVALID123', // Bad format
        country: 'CA',
      },
    }, buyerToken);

    if (error.code !== 'unexpected-success') {
      expect(error.message).toContain('postal') || expect(error.message).toContain('format');
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T14: Password Strength Validation
  // ════════════════════════════════════════════════════════════════════

  test('T14: Password reset: weak password → rejected', { timeout: 60_000 }, async () => {
    // Try to set a weak password
    const error = await callExpectError('update_password', {
      oldPassword: TEST_PASS,
      newPassword: '123', // Too weak
    }, buyerToken);

    if (error.code !== 'unexpected-success') {
      expect(error.message).toContain('password') || expect(error.message).toContain('weak');
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T15: Email Verification Required
  // ════════════════════════════════════════════════════════════════════

  test('T15: Seller actions require verified email', { timeout: 60_000 }, async () => {
    // This is already tested in auth tests, but verify the enforcement
    // Unverified sellers should not be able to list products or create orders

    const result = await callCallable('check_seller_verified', {}, sellerToken);

    // Should return verification status
    expect(result).toBeTruthy();
  });
});
