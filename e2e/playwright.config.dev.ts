// playwright.config.dev.ts — Dev environment (orignagta-dev Firebase)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './playwright_ui',
  testMatch: '**/*.spec.ts',
  testIgnore: ['*.py'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? 'list' : 'html',
  timeout: 300 * 1000,
  expect: { timeout: 15 * 1000 },
  use: {
    actionTimeout: 15 * 1000,
    baseURL: process.env.E2E_TARGET_URL ?? 'https://orignagta-dev.web.app',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    bypassCSP: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
