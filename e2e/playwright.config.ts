import { defineConfig, devices } from '@playwright/test';

const envWorkersRaw = process.env.E2E_WORKERS;
const envWorkers = envWorkersRaw ? Number.parseInt(envWorkersRaw, 10) : undefined;
const runAllProjects = process.env.E2E_PROJECTS === 'all' || process.env.E2E_ALL_PROJECTS === '1';

export default defineConfig({
  testDir: '.',
  // The repository contains several audit/WIP specs under `tests/` that are not
  // stable against Flutter Web (CanvasKit) semantics yet. Keep the default
  // Playwright run focused on the staging smoke/infra suites.
  testIgnore: [
    'tests/**',
    'marketplace-e2e.spec.ts',
    'tests.spec.ts',
    'seed-emulator.ts',
  ],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: Number.isFinite(envWorkers) ? Math.max(1, envWorkers as number) : (process.env.CI ? 1 : 2),
  reporter: process.env.CI ? 'list' : 'html',
  timeout: 90 * 1000, // 90 seconds for Flutter Web
  expect: {
    timeout: 30 * 1000, // 30 seconds for Flutter rendering
  },
  use: {
    actionTimeout: 30 * 1000,
    baseURL: 'http://localhost:5005',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    // Enable for Flutter Web canvas accessibility
    bypassCSP: true,
  },

  projects: [
    // Flutter Web + CanvasKit is significantly slower/flakier on WebKit + mobile
    // emulation. Keep the default run focused on Chromium for speed and
    // stability; enable cross-browser via `E2E_PROJECTS=all`.
    ...(runAllProjects
      ? [
          {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
          },
          {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
          },
          {
            name: 'Mobile Chrome',
            use: { ...devices['Pixel 5'] },
          },
          {
            name: 'Mobile Safari',
            use: { ...devices['iPhone 12'] },
          },
        ]
      : [
          {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
          },
        ]),
  ],

  /*
  webServer: {
    command: 'cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta && ./start-e2e-services.sh',
    url: 'http://localhost:5005',
    reuseExistingServer: true,
    timeout: 120000, // 2 minutes
    stdout: 'pipe',
  },
  */
});
