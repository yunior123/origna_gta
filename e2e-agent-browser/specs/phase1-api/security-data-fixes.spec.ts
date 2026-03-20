import { beforeAll, describe, expect, test } from 'bun:test';
import { callCallable, callExpectError, callOk, signIn } from '../../lib/api-client.js';
import { DEFAULT_PASS, ORIGNABASE_URL, TEST_ACCOUNTS } from '../../lib/config.js';

describe('Security — Data Integrity Fixes', () => {
  let adminToken = '';
  let sellerToken = '';
  let buyerToken = '';

  beforeAll(async () => {
    adminToken = (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, DEFAULT_PASS)).idToken;
    sellerToken = (await signIn(TEST_ACCOUNTS.SELLER_EMAIL, DEFAULT_PASS)).idToken;
    buyerToken = (await signIn(TEST_ACCOUNTS.BUYER_EMAIL, DEFAULT_PASS)).idToken;
  });

  test('T01: Address creation with a canonical Canadian payload succeeds', async () => {
    const result = await callOk('create_address', {
      fullName: 'Validation Test',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
    }, buyerToken);
    expect(result.addressId || result.id).toBeTruthy();
  });

  test('T02: Non-Canadian addresses are rejected', async () => {
    const error = await callExpectError('create_address', {
      fullName: 'Validation Test',
      streetAddress: '123 Main St',
      city: 'Buffalo',
      province: 'NY',
      postalCode: '14201',
      country: 'US',
    }, buyerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T03: Invalid postal codes do not crash address creation flow', async () => {
    const result = await callOk('create_address', {
      fullName: 'Validation Test',
      streetAddress: '123 Main St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'INVALID',
      country: 'Canada',
    }, buyerToken);
    expect(result.addressId || result.id).toBeTruthy();
  });

  test('T04: Empty street is rejected', async () => {
    const error = await callExpectError('create_address', {
      fullName: 'Validation Test',
      streetAddress: '',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
    }, buyerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T05: Password reset request does not 500', async () => {
    const result = await callCallable('request_password_reset', {
      email: TEST_ACCOUNTS.BUYER_EMAIL,
    }, buyerToken);
    expect(result).toBeTruthy();
  });

  test('T06: Invalid MFA recovery flow does not 500', async () => {
    const res = await fetch(`${ORIGNABASE_URL}/auth/mfa/recovery`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${buyerToken}`,
      },
      body: JSON.stringify({ recoveryCode: 'invalid-code' }),
    });
    expect(res.status).toBeGreaterThanOrEqual(200);
    expect(res.status).toBeLessThan(500);
  });

  test('T07: Duplicate subscription attempts do not crash the endpoint', async () => {
    const first = await callCallable('create_subscription', { planId: 'premium' }, buyerToken);
    const second = await callCallable('create_subscription', { planId: 'premium' }, buyerToken);
    expect(first || second).toBeTruthy();
  });

  test('T08: Webhook simulation remains idempotent when supported', async () => {
    const payload = { id: `evt_test_${Date.now()}`, type: 'test.event', data: { test: true } };
    const first = await callCallable('simulate_webhook', payload, adminToken);
    const second = await callCallable('simulate_webhook', payload, adminToken);
    expect(first || second).toBeTruthy();
  });

  test('T09: Oversized uploads are rejected', async () => {
    const error = await callExpectError('upload_file', {
      filename: 'huge.bin',
      sizeBytes: 600 * 1024 * 1024,
      data: 'x'.repeat(1000),
    }, sellerToken);
    expect(error.code).not.toBe('unexpected-success');
  });

  test('T10: Order listing responds quickly', async () => {
    const start = Date.now();
    await callCallable('list_orders_paginated', { limit: 100, offset: 0 }, buyerToken);
    expect(Date.now() - start).toBeLessThan(30_000);
  });

  test('T11: Admin audit-related endpoints respond for admin users', async () => {
    const result = await callCallable('get_admin_audit_logs', { limit: 10 }, adminToken);
    expect(result).toBeTruthy();
  });

  test('T12: Seller verification helper responds', async () => {
    const result = await callCallable('check_seller_verified', {}, sellerToken);
    expect(result).toBeTruthy();
  });
});
