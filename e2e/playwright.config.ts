import { defineConfig, devices } from '@playwright/test';

const envWorkersRaw = process.env.E2E_WORKERS;
const envWorkers = envWorkersRaw ? Number.parseInt(envWorkersRaw, 10) : undefined;
const runAllProjects = process.env.E2E_PROJECTS === 'all' || process.env.E2E_ALL_PROJECTS === '1';

export default defineConfig({
  testDir: '.',
  // Ignore non-test files and seed scripts
  testIgnore: [
    'seed-emulator.ts',
    'mega-seed.ts',
    '*.py',  // Python helper scripts
  ],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  // 6 workers locally (85% of tests are API-only and fully parallelizable)
  workers: Number.isFinite(envWorkers) ? Math.max(1, envWorkers as number) : (process.env.CI ? 4 : 6),
  reporter: process.env.CI ? 'list' : 'html',
  // 60s default — only UI tests override to 120s via test.setTimeout()
  timeout: 60 * 1000,
  expect: {
    timeout: 15 * 1000,
  },
  use: {
    actionTimeout: 15 * 1000,
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
    command: 'cd .. && ./scripts/start-e2e-services.sh',
    url: 'http://localhost:5005',
    reuseExistingServer: true,
    timeout: 120000, // 2 minutes
    stdout: 'pipe',
  },
  */
});
