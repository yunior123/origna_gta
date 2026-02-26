import { test, expect } from '@playwright/test';

test.describe('Password Reset Routing', () => {
  // Use deployed environment URL or Dev depending on configuration
  // The default in playwright.config files will point to the respective environment.

  test('should render ResetPasswordScreen when mode=resetPassword is in URL', async ({ page, baseURL }) => {
    // Navigate to the reset password route with a fake oobCode
    await page.goto(`${baseURL}/?mode=resetPassword&oobCode=fake_oob_code_123456789`);

    // Wait for the app to load and route
    await page.waitForLoadState('networkidle');

    // Make sure we are not stuck at the login or home screen due to auth wrapper redirection
    // In Flutter Web, ensure we wait for the canvas or semantics to paint
    await page.waitForTimeout(3000); 

    // We can rely on the browser's title or specific UI elements rendered by flutter
    // Wait for the "Create New Password" text to appear on the screen
    const createNewPasswordText = page.locator('text=Create New Password');
    await expect(createNewPasswordText).toBeVisible({ timeout: 20000 });

    const newPasswordInput = page.getByLabel('New Password');
    const confirmPasswordInput = page.getByLabel('Confirm Password');
    
    await expect(newPasswordInput).toBeVisible();
    await expect(confirmPasswordInput).toBeVisible();

    const resetButton = page.locator('text=Reset Password').last();
    await expect(resetButton).toBeVisible();
    await resetButton.click();

    // Verify error state 
    await expect(page.locator('text=Password must be at least 6 characters')).toBeVisible();
  });
});