import { expect, test } from '@playwright/test';
import { getAuthProviders, ORIGNABASE_URL, WEB_APP_URL } from './api-helpers';
import { requireWebApp, waitForFlutter } from './flutter-helpers';

const TARGET_URL = WEB_APP_URL;

test.describe('Google Auth Contract', () => {
  test.setTimeout(180_000);

  test('web login button and backend readiness stay in sync', async ({ page }) => {
    await requireWebApp(page, TARGET_URL);
    await page.goto(`${TARGET_URL}/login`, { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page);

    const providers = await getAuthProviders();

    const googleProvider = providers.google ?? {};
    const googleButton = page.locator('[aria-label="login_google_button"]').first();
    const googleButtonVisible = await googleButton.isVisible().catch(() => false);

    expect(
      googleButtonVisible,
      'Web Google button visibility must match OrignaBase provider readiness',
    ).toBe(Boolean(googleProvider.enabled));

    if (!googleButtonVisible) {
      expect(
        Boolean(googleProvider.enabled),
        'Google provider must not be marked enabled when the button is hidden on web',
      ).toBeFalsy();
      return;
    }

    expect(
      Boolean(googleProvider.client_id_configured),
      'Visible Google sign-in requires a configured Google client ID',
    ).toBeTruthy();
    expect(
      Boolean(googleProvider.client_secret_configured),
      'Visible Google sign-in requires a configured Google client secret for backend redirects',
    ).toBeTruthy();

    const startResponse = await page.request.get(
      `${new URL('/auth/google/start', ORIGNABASE_URL).toString()}?redirect_to=${encodeURIComponent(
        `${TARGET_URL}/login`,
      )}`,
    );
    const location = startResponse.headers()['location'] ?? '';

    expect(
      startResponse.status(),
      'Visible Google sign-in must start a valid backend-owned redirect flow',
    ).toBeGreaterThanOrEqual(300);
    expect(location).toContain('accounts.google.com');
  });
});
