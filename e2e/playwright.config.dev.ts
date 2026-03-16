// playwright.config.dev.ts — Dev environment (orignagta-dev on VPS with Caddy)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './playwright_ui',
  testMatch: '**/*.spec.ts',
  testIgnore: ['*.py'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: 1,
  reporter: process.env.CI ? 'list' : 'html',
  timeout: 600 * 1000,
  expect: { timeout: 15 * 1000 },
  globalSetup:
    process.env.E2E_SKIP_GLOBAL_SETUP === 'true'
      ? undefined
      : './playwright_ui/global-setup.ts',
  use: {
    actionTimeout: 15 * 1000,
    baseURL: process.env.E2E_TARGET_URL ?? 'https://dev.orignagta.ca',
    trace: 'on-first-retry',
    screenshot: 'on',
    bypassCSP: true,
    serviceWorkers: 'block', // Prevent Flutter SW from causing delays on page navigation
  },
  outputDir: `${process.env.HOME}/Desktop/origna-screenshots/dev`,
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
