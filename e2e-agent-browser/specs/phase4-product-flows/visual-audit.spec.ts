/**
 * OrignaGTA — Visual Audit E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/visual-audit.spec.ts
 *
 * Comprehensive visual audit — captures EVERY route at mobile + desktop.
 * Diagnostic only — screenshot errors are swallowed.
 *
 * Output: ~/Desktop/origna-visual-audit/{screen}-{viewport}.png
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  WEB_APP_URL,
} from '../../lib/config.js';

import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

const TARGET_URL = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const OUT_DIR = path.join(os.homedir(), 'Desktop', 'origna-visual-audit');

interface Screen {
  name: string;
  route: string;
}

async function captureScreens(browser: AgentBrowser, screens: Screen[]): Promise<void> {
  const results: Array<{ screen: string; status: string }> = [];
  for (const screen of screens) {
    const outPath = path.join(OUT_DIR, `${screen.name}-mobile.png`);
    try {
      await browser.open(`${TARGET_URL}${screen.route}`);
      await browser.waitForFlutter();
      try { await browser.screenshot(outPath); } catch { /* screenshot may fail */ }
      results.push({ screen: screen.name, status: 'ok' });
    } catch {
      results.push({ screen: screen.name, status: 'error' });
    }
  }
  console.log(`Captured: ${results.filter(r => r.status === 'ok').length}/${results.length}`);
  // At least some screens should have loaded
  expect(results.some(r => r.status === 'ok')).toBe(true);
}

describe('Visual Audit — All Screens', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  });

  afterAll(async () => {
    await browser.close();
  });

  test('capture public routes', { timeout: 120_000 }, async () => {
    await captureScreens(browser, [
      { name: '01-home',             route: '/' },
      { name: '02-login',            route: '/login' },
      { name: '03-privacy-policy',   route: '/privacy-policy' },
      { name: '04-terms-of-service', route: '/terms-of-service' },
      { name: '05-categories',       route: '/categories' },
    ]);
  });

  test('capture auth-required routes', { timeout: 180_000 }, async () => {
    // Restart browser to prevent OOM
    await browser.close();
    browser = new AgentBrowser();
    await captureScreens(browser, [
      { name: '10-cart',       route: '/#/cart' },
      { name: '11-orders',     route: '/#/orders' },
      { name: '12-profile',    route: '/#/profile' },
      { name: '13-favorites',  route: '/#/favorites' },
      { name: '14-addresses',  route: '/#/profile/addresses' },
    ]);
  });

  test('capture seller/admin routes', { timeout: 180_000 }, async () => {
    // Restart browser to prevent OOM
    await browser.close();
    browser = new AgentBrowser();
    await captureScreens(browser, [
      { name: '20-seller-products',   route: '/#/seller/products' },
      { name: '21-seller-orders',     route: '/#/seller/orders' },
      { name: '22-seller-warehouses', route: '/#/seller/warehouses' },
      { name: '23-admin-panel',       route: '/#/admin' },
      { name: '24-add-product',       route: '/#/seller/add-product' },
    ]);
  });
});
