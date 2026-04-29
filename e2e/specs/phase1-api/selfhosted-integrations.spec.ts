import { describe, expect, test } from 'bun:test';
import { signIn } from '../../lib/auth.js';
import {
  obGraphQL,
  parseGraphQLValue,
  readDoc,
  writeDoc,
} from '../../lib/api-client.js';
import {
  ORIGNABASE_URL,
  TEST_ACCOUNTS,
  VENTURES_API_BASE,
  VENTURES_WEB_URL,
} from '../../lib/config.js';

function normalizeSearchHits(value: unknown): any[] {
  const parsed = parseGraphQLValue(value);
  if (Array.isArray(parsed)) return parsed;
  if (parsed && typeof parsed === 'object') {
    const object = parsed as Record<string, unknown>;
    if (Array.isArray(object.hits)) return object.hits;
    if (Array.isArray(object.results)) return object.results;
  }
  return [];
}

describe('Self-hosted integration regressions', () => {
  test('Postal contact delivery reports provider-backed support and confirmation emails', async () => {
    const unique = Date.now();
    const response = await fetch(`${VENTURES_API_BASE}/api/contact`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Origin: VENTURES_WEB_URL,
      },
      body: JSON.stringify({
        name: `Postal E2E ${unique}`,
        email: 'e2e-contact@orignaventures.ca',
        company: 'Origna E2E',
        service: 'origna_launch',
        message: `Postal provider regression ${unique}. Ignore this automated check.`,
      }),
    });

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body?.status).toBe('ok');
    expect(body?.emails?.support?.status).toBe('sent');
    expect(body?.emails?.support?.provider).toBe('postal');
    expect(body?.emails?.confirmation?.status).toBe('sent');
    expect(body?.emails?.confirmation?.provider).toBe('postal');
  }, 30_000);

  test('Meilisearch-backed GraphQL search returns known seeded products', async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const result = await obGraphQL(
      `query SearchProducts($index: String!, $query: String!, $limit: Int) {
        search(index: $index, query: $query, limit: $limit)
      }`,
      {
        index: 'products',
        query: 'solar',
        limit: 10,
      },
      auth.idToken,
    );

    expect(result.status).toBe(200);
    expect(result.body?.errors).toBeUndefined();

    const hits = normalizeSearchHits(result.body?.data?.search);
    expect(hits.length).toBeGreaterThan(0);
    expect(JSON.stringify(hits).toLowerCase()).toContain('solar');
  }, 30_000);

  test('GlitchTip is self-hosted and structured error events are writable', async () => {
    const glitchtipResponse = await fetch('https://glitchtip.orignagta.ca', { method: 'GET' });
    expect(glitchtipResponse.status).toBeLessThan(500);

    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const id = `e2e_glitchtip_error_${Date.now()}`;
    const internalEventId = `SE-20260429-${String(Date.now()).slice(-6)}`;
    const eventPayload = {
      internalEventId,
      errorCode: 'ORIGNA-SYS-999',
      userFacingMessage: 'E2E GlitchTip persistence check [ORIGNA-SYS-999]',
      sentryEventId: 'e2e-glitchtip-event',
      errorType: 'E2EError',
      errorMessage: 'Self-hosted GlitchTip/error_events regression',
      stackTrace: 'e2e stack trace',
      environment: 'e2e',
      source: 'e2e',
      routeOrAction: 'selfhosted-integrations.spec.ts',
      severity: 'error',
      status: 'new',
      fingerprint: `e2e-glitchtip-${id}`,
      userId: auth.localId,
      email: TEST_ACCOUNTS.BUYER_EMAIL,
      metadata: {
        provider: 'glitchtip',
        apiBase: ORIGNABASE_URL,
      },
      createdAt: new Date().toISOString(),
    };

    const wrote = await writeDoc(`error_events/${id}`, eventPayload, auth.idToken, false);
    expect(wrote).toBe(true);

    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const doc = await readDoc(`error_events/${id}`, adminAuth.idToken);
    expect(doc?.fields?.errorCode?.stringValue).toBe('ORIGNA-SYS-999');
    expect(doc?.fields?.sentryEventId?.stringValue).toBe('e2e-glitchtip-event');
  }, 30_000);
});
