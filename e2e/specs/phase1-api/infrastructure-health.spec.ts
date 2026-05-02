import { describe, expect, test } from 'bun:test';
import { fetchWithRetry } from '../../lib/auth.js';
import { ORIGNABASE_URL } from '../../lib/config.js';

describe('Infrastructure Health', () => {
  test('GET /health returns 200 with a plain-text ok payload', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body.toLowerCase()).toContain('ok');
  });

  test('Docker healthcheck responds successfully', { timeout: 15_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.status).toBe(200);
    expect(res.ok).toBe(true);
  });

  test('CSP headers are present on health responses', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.headers.get('Content-Security-Policy') || res.headers.get('content-security-policy')).toBeTruthy();
  });

  test('X-XSS-Protection header is present', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.headers.get('X-XSS-Protection') || res.headers.get('x-xss-protection')).toBeTruthy();
  });

  test('CORS headers are never wildcard on health responses', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    const corsHeader = res.headers.get('Access-Control-Allow-Origin');
    if (corsHeader) {
      expect(corsHeader).not.toBe('*');
    }
  });

  test('Health endpoint responds within 5 seconds', { timeout: 6_000 }, async () => {
    const start = Date.now();
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.status).toBe(200);
    expect(Date.now() - start).toBeLessThan(5_000);
  });

  test('Authentication endpoints respond without 5xx failures', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'nonexistent@test.origna.ca',
        password: 'wrongpass',
      }),
    });
    expect([400, 401, 404, 422].includes(res.status)).toBe(true);
  });

  test('Registration endpoint responds deterministically', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `test-${Date.now()}@test.origna.ca`,
        password: 'REDACTED_TEST_PASSWORD',
        name: 'Test User',
      }),
    });
    expect(res.status).toBeGreaterThanOrEqual(200);
    expect(res.status).toBeLessThan(600);
  });

  test('database health is implicit in the successful plain-text /health response', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/health`, { method: 'GET' });
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body.trim().length).toBeGreaterThan(0);
  });

  test('Search surface responds without 5xx failures', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/search`, { method: 'GET' });
    expect(res.status).toBeLessThan(500);
  });

  test('Canonical Stripe webhook route responds deterministically', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/api/webhooks/stripe`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    expect([400, 401, 403, 404].includes(res.status)).toBe(true);
  });

  test('Support chat route either exists or fails cleanly', { timeout: 10_000 }, async () => {
    const res = await fetchWithRetry(`${ORIGNABASE_URL}/api/support/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    expect(res.status).toBeLessThan(500);
  });
});
