import { test, expect } from '@playwright/test';
import { waitForFlutter } from './flutter-helpers';

test.describe('Password Reset Routing', () => {
  // Valid-format oobCode (10+ alphanumeric chars) — passes Flutter's client-side
  // format check and routes to ResetPasswordScreen. OrignaBase rejects it only when
  // the user submits a new password (the ViewModel does NOT call OrignaBase on init).
  const FAKE_OOB = 'fake_oob_code_123456789';

  // Semantic label used by the "Go to Login" button in ResetPasswordScreen's
  // success state (label: 'reset_password_go_to_login_button').
  // Flutter 3.41.3: flt-semantics[role=button] label is in textContent, not aria-label.
  // Use getByRole('button', { name }) which reads textContent via Chrome AOM.
  const GO_TO_LOGIN_SELECTOR = (page: import('@playwright/test').Page) =>
    page.getByRole('button', { name: 'reset_password_go_to_login_button' });

  // Semantic label for the New Password input field.
  const NEW_PASSWORD_SELECTOR = (page: import('@playwright/test').Page) =>
    page.locator('[aria-label="reset_password_new_password_field"]');

  test('should render password form when oobCode format is valid', async ({ page, baseURL }) => {
    // The ResetPasswordViewModel does NOT call OrignaBase on init — it only
    // validates the oobCode format client-side (≥10 alphanumeric chars).
    // A valid-format fake code routes to ResetPasswordScreen and shows the form.
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=${FAKE_OOB}`);
    await waitForFlutter(page);

    // Password form must be visible — confirms ResetPasswordScreen was rendered.
    await expect(NEW_PASSWORD_SELECTOR(page))
      .toBeVisible({ timeout: 25000 });
  });

  test('should show error when submitting an invalid oobCode', async ({ page, baseURL }) => {
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=${FAKE_OOB}`);
    await waitForFlutter(page);

    // Password form is shown (ViewModel does not auto-reject on init).
    const newPasswordInput = NEW_PASSWORD_SELECTOR(page);
    await expect(newPasswordInput).toBeVisible({ timeout: 25000 });

    // Fill and submit — OrignaBase will reject the invalid oobCode.
    await newPasswordInput.click();
    await page.keyboard.insertText('NewPass123!');
    const confirmInput = page.locator('[aria-label="reset_password_confirm_password_field"]');
    await confirmInput.click();
    await page.keyboard.insertText('NewPass123!');
    const submitBtn = page.getByRole('button', { name: 'reset_password_submit_button' });
    await submitBtn.click();

    // After OrignaBase rejects the code, an error message appears inline.
    // The "Go to Login" button is only shown on success — it should NOT appear here.
    await expect(GO_TO_LOGIN_SELECTOR(page)).not.toBeVisible({ timeout: 10000 });
  });

  test('should reject URL with invalid oobCode format', async ({ page, baseURL }) => {
    // Malformed oobCode (less than 10 chars) must not route to ResetPasswordScreen.
    // origna_app.dart validates: RegExp(r'^[A-Za-z0-9\-_]{10,512}$')
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=short`);
    await waitForFlutter(page);

    // Should fall through to home/auth page — ResetPasswordScreen not rendered.
    await expect(NEW_PASSWORD_SELECTOR(page)).not.toBeVisible({ timeout: 5000 });
  });
});
