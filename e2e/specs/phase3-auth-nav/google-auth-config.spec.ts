/**
 * OrignaGTA — Google Auth Config E2E Tests
 * =======================================
 * Verifies that the backend Google provider contract, OAuth redirect, and the
 * deployed login page's injected GIS client ID stay in sync.
 */
import { test, expect, describe } from 'bun:test';
import { chromium } from 'playwright';
import { getAuthProviders } from '../../lib/api-client.js';
import { WEB_APP_URL, ORIGNABASE_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

describe('Google Auth Contract', () => {
  test('web login button and backend readiness stay in sync', { timeout: 60_000 }, async () => {
    const providers = await getAuthProviders();
    const googleProvider = providers.google ?? {};
    const expectGoogleVisible = Boolean(googleProvider.enabled);
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1440, height: 1100 } });
    await page.goto(`${TARGET_URL}/login`, { waitUntil: 'load', timeout: 60_000 });
    await page.waitForTimeout(15_000);

    const loginState = await page.evaluate(() => {
      const metaContent =
        document
          .querySelector('meta[name="google-signin-client_id"]')
          ?.getAttribute('content')
          ?.trim() ?? '';
      const bodyText = document.body.innerText;
      return {
        metaContent,
        bodyText,
        semanticsNodes: document.querySelectorAll(
          'flt-semantics, [aria-label], [flt-semantics-identifier]',
        ).length,
      };
    });

    const googleButtonVisible =
      loginState.bodyText.includes('login_google_button') ||
      loginState.bodyText.toLowerCase().includes('continue with google') ||
      loginState.bodyText.toLowerCase().includes('continuer avec google');

    expect(
      googleButtonVisible,
    ).toBe(expectGoogleVisible);

    expect(loginState.semanticsNodes).toBeGreaterThan(0);

    if (!googleButtonVisible) {
      expect(expectGoogleVisible).toBeFalsy();
      await browser.close();
      return;
    }

    expect(Boolean(googleProvider.client_id_configured)).toBeTruthy();
    expect(Boolean(googleProvider.client_secret_configured)).toBeTruthy();
    expect(loginState.metaContent).not.toBe('__GOOGLE_WEB_CLIENT_ID__');
    expect(loginState.metaContent).toContain('.apps.googleusercontent.com');

    // Verify the backend redirect flow starts correctly
    const startResponse = await fetch(
      `${ORIGNABASE_URL}/auth/google/start?redirect_to=${encodeURIComponent(`${TARGET_URL}/login`)}`,
      { redirect: 'manual' },
    );
    const location = startResponse.headers.get('location') ?? '';

    expect(startResponse.status).toBeGreaterThanOrEqual(300);
    expect(location).toContain('accounts.google.com');
    expect(location).toContain('client_id=');
    expect(location).toContain('.apps.googleusercontent.com');

    const badFragmentResponse = await fetch(
      `${ORIGNABASE_URL}/auth/google/start?redirect_to=${encodeURIComponent(`${TARGET_URL}/login#`)}`,
      { redirect: 'manual' },
    );
    expect(badFragmentResponse.status).toBe(400);

    await browser.close();
  });
});
