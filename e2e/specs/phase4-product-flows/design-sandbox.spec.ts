/**
 * OrignaGTA — Design Sandbox E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/design-sandbox.spec.ts
 *
 * Visual design sandbox: captures every major screen/route.
 * Diagnostic only — screenshot errors are swallowed.
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  WEB_APP_URL,
} from '../../lib/config.js';

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const SANDBOX_DIR = path.join(os.homedir(), 'Desktop', 'origna-sandbox');

describe('Design Sandbox — Full Visual Capture', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    if (!fs.existsSync(SANDBOX_DIR)) {
      fs.mkdirSync(SANDBOX_DIR, { recursive: true });

  beforeEach(async () => { await browser.clearState(); });
    }
  });

  afterAll(async () => {
    await browser.close();
  });

  test('capture public screens', { timeout: 120_000 }, async () => {
    const screens = [
      { name: 'home', route: '/' },
      { name: 'login', route: '/login' },
      { name: 'privacy-policy', route: '/privacy-policy' },
      { name: 'terms-of-service', route: '/terms-of-service' },
      { name: 'categories', route: '/categories' },
    ];
    let ok = 0;
    for (const screen of screens) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        try { await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`)); } catch { /* screenshot may fail */ }
        ok++;
      } catch {
        // page navigation may fail
      }
    }
    expect(ok).toBeGreaterThan(0);
  });

  test('capture auth-required screens', { timeout: 180_000 }, async () => {
    // Restart browser to prevent OOM
    await browser.close();
    browser = new AgentBrowser();
    const screens = [
      { name: 'cart', route: '/#/cart' },
      { name: 'orders', route: '/#/orders' },
      { name: 'profile', route: '/#/profile' },
      { name: 'favorites', route: '/#/favorites' },
    ];
    let ok = 0;
    for (const screen of screens) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        try { await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`)); } catch { /* screenshot may fail */ }
        ok++;
      } catch {
        // page navigation may fail
      }
    }
    expect(ok).toBeGreaterThan(0);
  });

  test('capture seller/admin screens', { timeout: 180_000 }, async () => {
    // Restart browser to prevent OOM
    await browser.close();
    browser = new AgentBrowser();
    const screens = [
      { name: 'seller-products', route: '/#/seller/products' },
      { name: 'seller-orders', route: '/#/seller/orders' },
      { name: 'seller-warehouses', route: '/#/seller/warehouses' },
      { name: 'admin-panel', route: '/#/admin' },
    ];
    let ok = 0;
    for (const screen of screens) {
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        try { await browser.screenshot(path.join(SANDBOX_DIR, `${screen.name}-mobile.png`)); } catch { /* screenshot may fail */ }
        ok++;
      } catch {
        // page navigation may fail
      }
    }
    expect(ok).toBeGreaterThan(0);
  });
});
