/**
 * OrignaVentures live checkout tax verification.
 *
 * This proves the Ventures backend no longer hardcodes a manual HST line item
 * into the checkout payload. The live Stripe Checkout page should show tax as
 * address-based (`Enter address to calculate`) instead of a pre-applied fixed
 * amount before customer tax context is known.
 */
import { describe, expect, test } from 'bun:test';
import { chromium } from 'playwright';

const API_URL = 'https://api.orignaventures.ca/api/payments/create-checkout-session';

describe('OrignaVentures live tax checkout', () => {
  test('OrignaLaunch checkout uses live address-based tax calculation instead of a hardcoded HST line item', async () => {
    const response = await fetch(API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        service_code: 'origna_launch',
        payment_provider: 'stripe',
        payer_email: `e2e-tax-probe-${Date.now()}@orignaventures.ca`,
      }),
    });
    expect(response.status).toBe(200);

    const body = (await response.json()) as {
      checkoutUrl?: string;
      sessionId?: string;
      status?: string;
      provider?: string;
    };
    expect(body.provider).toBe('stripe');
    expect(body.status).toBe('awaiting_payment');
    expect(body.sessionId).toMatch(/^cs_/);
    expect(body.checkoutUrl).toContain('checkout.stripe.com');

    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1400, height: 1200 } });

    try {
      await page.goto(body.checkoutUrl!, {
        waitUntil: 'domcontentloaded',
        timeout: 60_000,
      });
      await page.waitForTimeout(5_000);

      const text = await page.locator('body').innerText();
      expect(text).toContain('OrignaLaunch');
      expect(text).toContain('Subtotal');
      expect(text).toContain('CA$3,000.00');
      expect(text).toContain('Tax');
      expect(text).toContain('Enter address to calculate');
      expect(text).not.toContain('HST (13%)');
      expect(text).not.toContain('CA$390.00');
    } finally {
      await browser.close();
    }
  }, 90_000);
});
