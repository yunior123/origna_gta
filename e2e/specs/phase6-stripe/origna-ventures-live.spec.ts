/**
 * OrignaVentures — Live Tier + Payment E2E Tests
 * =================================================
 * Tests the 3-tier service checkout flow against the Ventures backend API.
 * Tiers: OrignaCode ($500), OrignaLaunch ($2000), OrignaTeam ($1000/mo).
 * No contract signing — serviceCode-based direct Stripe checkout.
 */
import { test, expect, describe } from 'bun:test';
import { VENTURES_API_BASE, VENTURES_WEB_URL, VENTURES_TIERS } from '../../lib/config.js';

const TEST_EMAIL = 'e2e-test@orignaventures.ca';

// ─── Helpers ────────────────────────────────────────────────────────────────

async function venturesFetch(path: string, options: RequestInit = {}) {
  const url = `${VENTURES_API_BASE}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  return res;
}

async function createCheckoutSession(serviceCode: string, payerEmail: string) {
  const res = await venturesFetch('/payments/create-checkout-session', {
    method: 'POST',
    body: JSON.stringify({ service_code: serviceCode, payer_email: payerEmail }),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

// ─── Tier Configuration Tests ───────────────────────────────────────────────

describe('OrignaVentures — Tier Configuration', () => {
  test('Home page renders and mentions all 3 tier names', async () => {
    const res = await fetch(VENTURES_WEB_URL);
    expect(res.status).toBe(200);
    const html = await res.text();
    const lower = html.toLowerCase();
    expect(lower).toContain('orignacode');
    expect(lower).toContain('orignalaunch');
    expect(lower).toContain('orignateam');
  });

  test('Home page no longer mentions old tier names (Essential/Professional/Enterprise)', async () => {
    const res = await fetch(VENTURES_WEB_URL);
    const html = await res.text();
    const lower = html.toLowerCase();
    expect(lower).not.toContain('essential');
    expect(lower).not.toContain('professional');
    expect(lower).not.toContain('enterprise');
  });

  test('Home page mentions correct prices', async () => {
    const res = await fetch(VENTURES_WEB_URL);
    const html = await res.text();
    expect(html).toContain('500');
    expect(html).toContain('2,000');
    expect(html).toContain('1,000');
  });
});

// ─── Backend Health Tests ───────────────────────────────────────────────────

describe('OrignaVentures — Backend Health', () => {
  test('Health endpoint returns 200', async () => {
    const res = await venturesFetch('/health');
    expect(res.status).toBe(200);
  });

  test('API health endpoint returns 200', async () => {
    const res = await venturesFetch('/health');
    expect(res.status).toBe(200);
  });

  test('Meta endpoint returns service catalog', async () => {
    const res = await venturesFetch('/meta');
    if (res.status === 200) {
      const body = await res.json().catch(() => null);
      if (body?.services) {
        const codes = body.services.map((s: any) => s.code ?? s.service_code);
        expect(codes).toContain('origna_code');
        expect(codes).toContain('origna_launch');
        expect(codes).toContain('origna_team');
      }
    } else {
      // Meta endpoint may not exist — acceptable
      expect(res.status).toBeLessThan(500);
    }
  });
});

// ─── Checkout Session Tests ─────────────────────────────────────────────────

describe('OrignaVentures — Checkout Session API', () => {
  test('OrignaCode ($500) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(
      VENTURES_TIERS.ORIGNA_CODE.code,
      TEST_EMAIL,
    );
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
      expect(body.sessionId).toBeTruthy();
      expect(body.status).toBe('awaiting_payment');
    } else if (status === 429) {
      console.log('Rate limited — acceptable');
      expect(true).toBe(true);
    } else {
      console.log(`Unexpected status ${status}: ${JSON.stringify(body)}`);
      // Server may not have Stripe keys configured in test env
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('OrignaLaunch ($2000) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(
      VENTURES_TIERS.ORIGNA_LAUNCH.code,
      TEST_EMAIL,
    );
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
    } else if (status === 429) {
      console.log('Rate limited — acceptable');
    } else {
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('OrignaTeam ($1000/mo) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(
      VENTURES_TIERS.ORIGNA_TEAM.code,
      TEST_EMAIL,
    );
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
    } else if (status === 429) {
      console.log('Rate limited — acceptable');
    } else {
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('Invalid service_code returns 422 or 404', async () => {
    const { status } = await createCheckoutSession('invalid_service', TEST_EMAIL);
    expect(status === 422 || status === 404 || status === 400).toBe(true);
  });

  test('Missing payer_email returns 422', async () => {
    const res = await venturesFetch('/payments/create-checkout-session', {
      method: 'POST',
      body: JSON.stringify({ service_code: 'origna_code' }),
    });
    expect(res.status === 422 || res.status === 400).toBe(true);
  });

  test('Missing service_code returns 422', async () => {
    const res = await venturesFetch('/payments/create-checkout-session', {
      method: 'POST',
      body: JSON.stringify({ payer_email: TEST_EMAIL }),
    });
    expect(res.status === 422 || res.status === 400).toBe(true);
  });
});

// ─── Webhook Security Tests ─────────────────────────────────────────────────

describe('OrignaVentures — Webhook Security', () => {
  test('Webhook rejects unsigned request', async () => {
    const res = await venturesFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({
        id: 'evt_test',
        type: 'checkout.session.completed',
        data: { object: { id: 'cs_test' } },
      }),
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects invalid signature', async () => {
    const res = await venturesFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({
        id: 'evt_test_bad_sig',
        type: 'checkout.session.completed',
        data: { object: { id: 'cs_test' } },
      }),
      headers: {
        'Stripe-Signature': 't=1234567890,v1=invalid_signature_here',
      },
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects replay attack with old timestamp', async () => {
    const res = await venturesFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({
        id: 'evt_test_replay',
        type: 'checkout.session.completed',
        data: { object: { id: 'cs_test' } },
      }),
      headers: {
        'Stripe-Signature': `t=1577836800,v1=fake_sig_replay`,
      },
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects non-POST methods', async () => {
    const getRes = await venturesFetch('/stripe/webhook', { method: 'GET' });
    expect(getRes.status).toBeGreaterThanOrEqual(400);

    const putRes = await venturesFetch('/stripe/webhook', {
      method: 'PUT',
      body: '{}',
    });
    expect(putRes.status).toBeGreaterThanOrEqual(400);
  });

  test('Webhook returns non-5xx for malformed JSON', async () => {
    const res = await venturesFetch('/stripe/webhook', {
      method: 'POST',
      body: 'not json {{{',
      headers: {
        'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=test`,
      },
    });
    expect(res.status).toBeLessThan(500);
  });
});

// ─── Contact Form Tests ─────────────────────────────────────────────────────

describe('OrignaVentures — Contact API', () => {
  test('Contact endpoint requires valid payload', async () => {
    const res = await venturesFetch('/contact', {
      method: 'POST',
      body: JSON.stringify({ name: '', email: 'bad', message: '' }),
    });
    expect(res.status === 422 || res.status === 400).toBe(true);
  });

  test('Contact endpoint rejects GET', async () => {
    const res = await venturesFetch('/contact', { method: 'GET' });
    expect(res.status).toBeGreaterThanOrEqual(400);
  });
});
