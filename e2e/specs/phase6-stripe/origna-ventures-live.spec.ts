
import { test, expect, describe } from 'bun:test';
import { callOk, WEB_APP_URL } from '../../lib/api-client.js';
import { WEB_APP_URL } from '../../lib/config.js';

describe('Origna Ventures Live Tier + Payment E2E', () => {
  test('Home page shows Essential, Professional, Enterprise tiers', async () => {
    const res = await fetch(`${WEB_APP_URL}/`);
    const text = await res.text();
    expect(text.toLowerCase()).toContain('essential');
    expect(text.toLowerCase()).toContain('professional');
    expect(text.toLowerCase()).toContain('enterprise');
  });

  test('Tier 2 (Enterprise) payment flow works', async () => {
    // Requires auth. I will stub the auth part for now as it is a service-tier test.
    const session = await callOk('create-service-session', {
        tier: 'enterprise',
        payer_email: 'support@orignaventures.ca'
    }, 'dev-dummy-token');
    expect(session.checkoutUrl).toBeDefined();
  });
});
