import { test, expect } from '@playwright/test';

test.describe('Password Reset Routing', () => {
  // Use deployed environment URL or Dev depending on configuration
  // The default in playwright.config files will point to the respective environment.

  test('should render ResetPasswordScreen when mode=resetPassword is in URL', async ({ page, baseURL }) => {
    // Navigate to the reset password route with a fake oobCode (valid format: 10-512 alphanumeric chars)
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=fake_oob_code_123456789`);

    // Wait for the app to load and route
    await page.waitForLoadState('networkidle');

    // We can rely on the browser's title or specific UI elements rendered by flutter
    // Wait for the "Reset Password" title to appear on the screen
    await expect(page.getByRole('heading').filter({ hasText: /Reset Password/i }))
      .toBeVisible({ timeout: 20000 });
  });

  test('should show error and Go to Login when oobCode is invalid/expired', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=fake_oob_code_123456789`);
    await page.waitForLoadState('networkidle');

    // After Firebase rejects the invalid code, screen should show error + "Go to Login" button
    // (no password form — gated on state.userEmail != null)
    const goToLoginBtn = page.getByRole('button', { name: /go to login/i });
    await expect(goToLoginBtn).toBeVisible({ timeout: 20000 });

    // Password form must NOT be visible for invalid oobCode
    await expect(page.getByLabel('New Password')).not.toBeVisible();
  });

  test('should reject URL with invalid oobCode format', async ({ page, baseURL }) => {
    // Malformed oobCode (less than 10 chars) must not route to ResetPasswordScreen
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=short`);
    await page.waitForLoadState('networkidle');

    // Should fall through to home/auth page, not the reset password screen
    await expect(page.getByRole('button', { name: /go to login/i })).not.toBeVisible({ timeout: 5000 });
  });
});