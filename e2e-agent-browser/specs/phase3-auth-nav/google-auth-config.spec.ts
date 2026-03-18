/**
 * OrignaGTA — Google Auth Config E2E Tests (agent-browser + Bun)
 * ================================================================
 * Verifies that the web Google Sign-In button and backend provider config
 * stay in sync (button visible IFF backend has Google enabled + configured).
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { getAuthProviders } from '../../lib/api-client.js';
import { WEB_APP_URL, ORIGNABASE_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

describe('Google Auth Contract', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('web login button and backend readiness stay in sync', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET_URL}/login`);
    await browser.waitForFlutter();

    const providers = await getAuthProviders();
    const googleProvider = providers.google ?? {};

    // Wait for full login form to render (Google button appears last)
    const snap = await browser.waitForChange({ text: /login_submit_button/i, timeout: 30_000 });
    const googleButton = browser.findByLabel(snap, /login_google_button|btn-google|continuer avec Google|continue with Google/i);
    const googleButtonVisible = googleButton !== null;

    expect(
      googleButtonVisible,
    ).toBe(Boolean(googleProvider.enabled));

    if (!googleButtonVisible) {
      expect(Boolean(googleProvider.enabled)).toBeFalsy();
      return;
    }

    expect(Boolean(googleProvider.client_id_configured)).toBeTruthy();
    expect(Boolean(googleProvider.client_secret_configured)).toBeTruthy();

    // Verify the backend redirect flow starts correctly
    const startResponse = await fetch(
      `${ORIGNABASE_URL}/auth/google/start?redirect_to=${encodeURIComponent(`${TARGET_URL}/login`)}`,
      { redirect: 'manual' },
    );
    const location = startResponse.headers.get('location') ?? '';

    expect(startResponse.status).toBeGreaterThanOrEqual(300);
    expect(location).toContain('accounts.google.com');
  });
});
