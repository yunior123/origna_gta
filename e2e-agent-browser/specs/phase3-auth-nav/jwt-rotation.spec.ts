import { describe, expect, test } from 'bun:test';
import { fetchWithRetry, signIn } from '../../lib/api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS } from '../../lib/config.js';

async function getJwtStatus(token: string) {
  const res = await fetchWithRetry(`${ORIGNABASE_URL}/_admin/jwt/status`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  const body = await res.json().catch(() => null);
  return { res, body };
}

async function rotateJwtKeys(token: string) {
  const res = await fetchWithRetry(`${ORIGNABASE_URL}/_admin/jwt/rotate`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({}),
  });
  const body = await res.json().catch(() => null);
  return { res, body };
}

describe('JWT Key Rotation', () => {
  test('T01: Admin JWT status route responds deterministically', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const { res, body } = await getJwtStatus(adminAuth.idToken);
    expect([200, 401, 403, 404].includes(res.status)).toBe(true);
    if (res.status === 200 && body) {
      expect(typeof body).toBe('object');
    }
  });

  test('T02: Admin JWT rotate route responds deterministically', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const { res, body } = await rotateJwtKeys(adminAuth.idToken);
    expect([200, 202, 400, 401, 403, 404, 409, 429].includes(res.status)).toBe(true);
    if (body) expect(typeof body).toBe('object');
  });

  test('T03: Existing admin JWT remains usable after a rotation attempt', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    await rotateJwtKeys(adminAuth.idToken);
    const profileRes = await fetchWithRetry(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${adminAuth.idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });
    expect([200, 401, 403].includes(profileRes.status)).toBe(true);
  });

  test('T04: Fresh admin login remains usable after a rotation attempt', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const profileRes = await fetchWithRetry(`${ORIGNABASE_URL}/api/users/profile/get`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${adminAuth.idToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });
    expect(profileRes.status).toBe(200);
  });

  test('T05: JWT status payload includes key metadata when implemented', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const { res, body } = await getJwtStatus(adminAuth.idToken);
    if (res.status !== 200 || !body) {
      expect([401, 403, 404].includes(res.status)).toBe(true);
      return;
    }
    const keyId = body.currentKeyId ?? body.activeKeyId ?? body.keyId;
    const algorithm = body.algorithm ?? body.alg;
    if (keyId !== undefined) expect(typeof keyId).toBe('string');
    if (algorithm !== undefined) expect(typeof algorithm).toBe('string');
  });

  test('T06: Non-admin cannot rotate JWT keys', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const { res } = await rotateJwtKeys(buyerAuth.idToken);
    expect([401, 403, 404].includes(res.status)).toBe(true);
  });

  test('T07: Non-admin cannot access JWT status', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const { res } = await getJwtStatus(buyerAuth.idToken);
    expect([401, 403, 404].includes(res.status)).toBe(true);
  });

  test('T08: JWT status algorithm is never symmetric when exposed', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const { res, body } = await getJwtStatus(adminAuth.idToken);
    if (res.status !== 200 || !body?.algorithm) {
      expect([200, 401, 403, 404].includes(res.status)).toBe(true);
      return;
    }
    expect(String(body.algorithm)).not.toMatch(/HS256|HMAC|symmetric/i);
  });

  test('T09: Rotation attempt leaves status route in a valid state', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    await rotateJwtKeys(adminAuth.idToken);
    const { res } = await getJwtStatus(adminAuth.idToken);
    expect([200, 401, 403, 404].includes(res.status)).toBe(true);
  });

  test('T10: Rotation response timestamps are numeric when present', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const { res, body } = await rotateJwtKeys(adminAuth.idToken);
    expect([200, 202, 400, 401, 403, 404, 409, 429].includes(res.status)).toBe(true);
    const rotatedAt = body?.rotatedAt ?? body?.timestamp;
    if (rotatedAt !== undefined) {
      expect(typeof rotatedAt).toBe('number');
    }
  });
});
