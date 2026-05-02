/**
 * Lightweight live contracts for OrignaVentures mobile pricing.
 *
 * Browser-level mobile pricing coverage lives in origna-ventures-live.spec.ts.
 * This file avoids duplicate Chromium launches in the full phase6 suite.
 */
import { expect, test } from 'bun:test';
import { VENTURES_API_BASE, VENTURES_WEB_URL } from '../../lib/config.js';

test('deployed Ventures page is reachable for mobile pricing flow', async () => {
  const res = await fetch(VENTURES_WEB_URL);
  expect(res.status).toBe(200);
  const html = await res.text();
  expect(html.toLowerCase()).toContain('origna ventures');
});

test('launch tier checkout contract returns Stripe URL', async () => {
  const res = await fetch(`${VENTURES_API_BASE}/api/payments/create-checkout-session`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Origin: VENTURES_WEB_URL,
    },
    body: JSON.stringify({
      service_code: 'origna_launch',
      payer_email: 'e2e-test@orignaventures.ca',
    }),
  });
  const body = await res.json().catch(() => null);

  expect(res.status, `checkout create failed: ${JSON.stringify(body)}`).toBe(200);
  expect(body?.provider).toBe('stripe');
  expect(body?.checkoutUrl).toContain('checkout.stripe.com');
  expect(body?.sessionId).toBeTruthy();
});
