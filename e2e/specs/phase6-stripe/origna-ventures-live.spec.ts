import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser';

const TARGET_URL = process.env.E2E_TARGET_URL ?? 'https://www.orignaventures.ca';
const API_BASE = process.env.E2E_VENTURES_API_URL ?? 'https://api.orignagta.ca/ventures/api';
const WEBHOOK_SECRET = process.env.E2E_VENTURES_WEBHOOK_SECRET ?? 'STRIPE_WEBHOOK_SECRET_REDACTED';

let browser: AgentBrowser;

beforeAll(async () => {
  browser = new AgentBrowser({ engine: 'chrome' });
}, 10_000);

beforeEach(async () => {
  await browser.clearState();
});

afterAll(async () => {
  await browser.close();
});

async function pageText(route: string): Promise<string> {
  await browser.open(`${TARGET_URL}${route}`);
  await browser.enableAccessibilityIfPresent().catch(() => false);
  try {
    await browser.waitForFlutter();
  } catch {
    await browser.enableAccessibilityIfPresent().catch(() => false);
    await browser.waitForFlutter(10_000).catch(() => undefined);
  }
  const snap = await browser.snapshot({ interactive: true, compact: true });
  return snap.refs
    .map((ref) => [ref.name, ref.text].filter(Boolean).join(' '))
    .join(' ')
    .toLowerCase();
}

async function postJson(url: string, body: unknown, headers?: Record<string, string>) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(headers ?? {}),
    },
    body: JSON.stringify(body),
  });
  const text = await response.text();
  let parsed: unknown = text;
  try {
    parsed = JSON.parse(text);
  } catch {
    // leave raw text when upstream does not return JSON
  }
  return { status: response.status, body: parsed };
}

describe('Origna Ventures Live QR + Payment E2E', () => {
  test('QR destination routes render meaningful content', async () => {
    const expectations: Array<[string, string[]]> = [
      ['/', ['origna ventures', 'orignalaunch', 'sign contract', 'source code']],
      ['/contract', ['electronic signing', 'typed signature', 'github username', 'sign now']],
      ['/pay', ['secure payment', 'contract id', 'payer email', 'pay now']],
      ['/deck', ['full screenshot deck', '464,042 total lines of code', 'flutter web']],
      ['/donate', ['community giving', 'church/community giving', 'donation']],
      ['/partner', ['partner program', '5% of generated net revenue', 'affiliate']],
    ];

    for (const [route, needles] of expectations) {
      const text = await pageText(route);
      expect(
        needles.some((needle) => text.includes(needle)),
        `Route ${route} did not expose any expected keywords. Snapshot text: ${text.slice(0, 500)}`,
      ).toBe(true);
    }
  }, 180_000);

  test('Live payment flow creates Stripe checkout and opens Stripe page', async () => {
    const sign = await postJson(`${API_BASE}/contracts/sign`, {
      service_code: 'origna_launch',
      locale: 'en',
      client_name: 'Yunior Rodriguez Osorio',
      client_email: 'support@orignaventures.ca',
      client_company: 'Origna Ventures Services',
      client_phone: '4167865517',
      client_address: 'Toronto, Ontario, Canada',
      signer_full_name: 'Yunior Rodriguez Osorio',
      signer_title: 'Founder',
      github_username: 'yunior123',
      typed_signature: 'Yunior Rodriguez Osorio',
      consent_checked: true,
    });
    expect(sign.status).toBe(200);
    const signBody = sign.body as Record<string, unknown>;
    const contractId = String(signBody.contractId ?? '');
    expect(contractId.startsWith('ovc_')).toBe(true);

    const payment = await postJson(`${API_BASE}/payments/create-checkout-session`, {
      contract_id: contractId,
      payer_email: 'support@orignaventures.ca',
      payment_provider: 'stripe',
    });
    expect(payment.status).toBe(200);
    const paymentBody = payment.body as Record<string, unknown>;
    const checkoutUrl = String(paymentBody.checkoutUrl ?? '');
    expect(checkoutUrl.includes('checkout.stripe.com')).toBe(true);

    await browser.open(checkoutUrl, 60_000);
    const stripeUrl = browser.run(['eval', 'window.location.href'], 10_000).trim().replace(/^"|"$/g, '');
    expect(stripeUrl.includes('checkout.stripe.com')).toBe(true);
  }, 180_000);

  test('Signed webhook marks a paid contract as unlocked or already accessible', async () => {
    const sign = await postJson(`${API_BASE}/contracts/sign`, {
      service_code: 'origna_launch',
      locale: 'en',
      client_name: 'Yunior Rodriguez Osorio',
      client_email: 'support@orignaventures.ca',
      client_company: 'Origna Ventures Services',
      client_phone: '4167865517',
      client_address: 'Toronto, Ontario, Canada',
      signer_full_name: 'Yunior Rodriguez Osorio',
      signer_title: 'Founder',
      github_username: 'yunior123',
      typed_signature: 'Yunior Rodriguez Osorio',
      consent_checked: true,
    });
    expect(sign.status).toBe(200);
    const contractId = String((sign.body as Record<string, unknown>).contractId ?? '');

    const payment = await postJson(`${API_BASE}/payments/create-checkout-session`, {
      contract_id: contractId,
      payer_email: 'support@orignaventures.ca',
      payment_provider: 'stripe',
    });
    expect(payment.status).toBe(200);
    const paymentBody = payment.body as Record<string, unknown>;
    const sessionId = String(paymentBody.sessionId ?? '');
    expect(sessionId.length).toBeGreaterThan(10);

    const event = {
      id: `evt_unlock_${Date.now()}`,
      type: 'checkout.session.completed',
      data: {
        object: {
          id: sessionId,
          payment_status: 'paid',
          metadata: { contract_id: contractId },
        },
      },
    };
    const raw = JSON.stringify(event);
    const ts = String(Math.floor(Date.now() / 1000));
    const crypto = await import('node:crypto');
    const sig = crypto
      .createHmac('sha256', WEBHOOK_SECRET)
      .update(`${ts}.${raw}`)
      .digest('hex');

    const webhook = await fetch(`${API_BASE}/stripe/webhook`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'stripe-signature': `t=${ts},v1=${sig}`,
      },
      body: raw,
    });
    expect(webhook.status).toBe(200);

    const contractsResponse = await fetch(`${API_BASE}/contracts`);
    expect(contractsResponse.status).toBe(200);
    const contractsBody = (await contractsResponse.json()) as {
      contracts: Array<Record<string, unknown>>;
    };
    const row = contractsBody.contracts.find((contract) => contract.id === contractId);
    expect(row).toBeDefined();
    expect(row?.status).toBe('paid');
    expect(['invited', 'already_has_access'].includes(String(row?.repo_unlock_status))).toBe(true);
  }, 180_000);
});
