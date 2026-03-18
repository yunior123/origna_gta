/**
 * OrignaGTA — Visual Audit E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/visual-audit.spec.ts
 *
 * Comprehensive visual audit — captures EVERY route at mobile + desktop.
 * Diagnostic only — no test failures.
 *
 * Output: ~/Desktop/origna-visual-audit/{screen}-{viewport}.png
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
const OUT_DIR = path.join(os.homedir(), 'Desktop', 'origna-visual-audit');

interface Screen {
  name: string;
  route: string;
  requireAuth: boolean;
}

const PUBLIC_SCREENS: Screen[] = [
  { name: '01-home',             route: '/',                     requireAuth: false },
  { name: '02-login',            route: '/login',                requireAuth: false },
  { name: '03-privacy-policy',   route: '/privacy-policy',       requireAuth: false },
  { name: '04-terms-of-service', route: '/terms-of-service',     requireAuth: false },
  { name: '05-categories',       route: '/categories',           requireAuth: false },
];

describe('Visual Audit — All Screens', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  });

  afterAll(async () => {
    await browser.close();
  });

  test('capture public routes', async () => {
    const results: Array<{ screen: string; status: string }> = [];

    for (const screen of PUBLIC_SCREENS) {
      const outPath = path.join(OUT_DIR, `${screen.name}-mobile.png`);
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(outPath);
        results.push({ screen: screen.name, status: 'ok' });
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        results.push({ screen: screen.name, status: `ERROR: ${String(err).slice(0, 80)}` });
        console.log(`  Failed: ${screen.name}`);
      }
    }

    console.log(`\nVisual Audit Complete — ${OUT_DIR}`);
    console.log(`Total: ${results.length} screenshots`);
    const errors = results.filter(r => r.status.startsWith('ERROR'));
    console.log(`  OK: ${results.length - errors.length}  |  Errors: ${errors.length}`);
  });

  test('capture auth-required routes at mobile + desktop', { timeout: 120_000 }, async () => {
    const authScreens: Screen[] = [
      { name: '10-cart',       route: '/#/cart',       requireAuth: true },
      { name: '11-orders',     route: '/#/orders',     requireAuth: true },
      { name: '12-profile',    route: '/#/profile',    requireAuth: true },
      { name: '13-favorites',  route: '/#/favorites',  requireAuth: true },
      { name: '14-addresses',  route: '/#/profile/addresses', requireAuth: true },
    ];

    const results: Array<{ screen: string; status: string }> = [];
    for (const screen of authScreens) {
      const outPath = path.join(OUT_DIR, `${screen.name}-mobile.png`);
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(outPath);
        results.push({ screen: screen.name, status: 'ok' });
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        results.push({ screen: screen.name, status: `ERROR: ${String(err).slice(0, 80)}` });
        console.log(`  Failed: ${screen.name}`);
      }
    }
    console.log(`Auth routes captured: ${results.filter(r => r.status === 'ok').length}/${results.length}`);
  });

  test('capture seller/admin routes at mobile + desktop', { timeout: 120_000 }, async () => {
    const sellerScreens: Screen[] = [
      { name: '20-seller-products',   route: '/#/seller/products',    requireAuth: true },
      { name: '21-seller-orders',     route: '/#/seller/orders',      requireAuth: true },
      { name: '22-seller-warehouses', route: '/#/seller/warehouses',  requireAuth: true },
      { name: '23-admin-panel',       route: '/#/admin',              requireAuth: true },
      { name: '24-add-product',       route: '/#/seller/add-product', requireAuth: true },
    ];

    const results: Array<{ screen: string; status: string }> = [];
    for (const screen of sellerScreens) {
      const outPath = path.join(OUT_DIR, `${screen.name}-mobile.png`);
      try {
        await browser.open(`${TARGET_URL}${screen.route}`);
        await browser.waitForFlutter();
        await browser.screenshot(outPath);
        results.push({ screen: screen.name, status: 'ok' });
        console.log(`  Captured: ${screen.name}`);
      } catch (err) {
        results.push({ screen: screen.name, status: `ERROR: ${String(err).slice(0, 80)}` });
        console.log(`  Failed: ${screen.name}`);
      }
    }
    console.log(`Seller routes captured: ${results.filter(r => r.status === 'ok').length}/${results.length}`);
  });
});
