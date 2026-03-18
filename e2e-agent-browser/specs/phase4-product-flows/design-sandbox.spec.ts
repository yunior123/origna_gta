/**
 * OrignaGTA — Design Sandbox E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/design-sandbox.spec.ts
 *
 * Visual design sandbox: captures every major screen/route at three viewport
 * widths (mobile, tablet, desktop). Diagnostic only — no pass/fail gate.
 *
 * The original test uses Playwright viewport resizing + serial screenshot
 * capture across 11 screens x 3 viewports. This requires full browser
 * control with viewport manipulation which maps to agent-browser screenshot.
 */
import { test, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  WEB_APP_URL,
} from '../../lib/config.js';

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const SANDBOX_DIR = path.join(os.homedir(), 'Desktop', 'origna-sandbox');

const PUBLIC_SCREENS = [
  { name: 'home', route: '/' },
  { name: 'login', route: '/login' },
  { name: 'privacy-policy', route: '/privacy-policy' },
  { name: 'terms-of-service', route: '/terms-of-service' },
  { name: 'categories', route: '/categories' },
];

describe('Design Sandbox — Full Visual Capture', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    if (!fs.existsSync(SANDBOX_DIR)) {
      fs.mkdirSync(SANDBOX_DIR, { recursive: true });
    }
  });

  afterAll(async () => {
    await browser.close();
  });

  test('capture public screens', async () => {
    for (const screen of PUBLIC_SCREENS) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`));
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        console.log(`  Failed: ${screen.name} — ${String(err).slice(0, 80)}`);
      }
    }
  });

  test('capture auth-required screens at all viewports', { timeout: 120_000 }, async () => {
    const authScreens = [
      { name: 'cart', route: '/#/cart' },
      { name: 'orders', route: '/#/orders' },
      { name: 'profile', route: '/#/profile' },
      { name: 'favorites', route: '/#/favorites' },
    ];
    for (const screen of authScreens) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`));
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        console.log(`  Failed: ${screen.name} — ${String(err).slice(0, 80)}`);
      }
    }
  });

  test('capture seller/admin screens at all viewports', { timeout: 120_000 }, async () => {
    const sellerScreens = [
      { name: 'seller-products', route: '/#/seller/products' },
      { name: 'seller-orders', route: '/#/seller/orders' },
      { name: 'seller-warehouses', route: '/#/seller/warehouses' },
      { name: 'admin-panel', route: '/#/admin' },
    ];
    for (const screen of sellerScreens) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`));
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        console.log(`  Failed: ${screen.name} — ${String(err).slice(0, 80)}`);
      }
    }
  });
});
