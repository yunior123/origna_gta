/**
 * OrignaGTA — Page Load Performance Measurement
 * ================================================
 * Migrated from e2e/playwright_ui/measure-load2.spec.ts
 * Uses agent-browser + bun:test instead of Playwright.
 *
 * Measures wall-clock time for Flutter Web to render on home and login pages.
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { WEB_APP_URL } from '../../lib/config.js';

const TARGET_URL = WEB_APP_URL;

let browser: AgentBrowser;

beforeAll(async () => {
  browser = new AgentBrowser();
}, 10_000);

afterAll(async () => {
  await browser.close();
});

  beforeEach(async () => { await browser.clearState(); });

describe('Page Load Performance', () => {

  test('measure home page load time', async () => {
    const t0 = Date.now();

    await browser.open(`${TARGET_URL}/`);
    const tOpen = Date.now();
    console.log(`1-open: ${tOpen - t0}ms`);

    await browser.waitForFlutter(90_000);
    const tFlutter = Date.now();
    console.log(`1-flutter-ready: ${tFlutter - t0}ms`);

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const tSnapshot = Date.now();
    console.log(`1-snapshot: ${tSnapshot - t0}ms (${snap.refs.length} refs)`);

    // Flutter should have loaded within a reasonable time
    expect(snap.refs.length).toBeGreaterThan(0);
    console.log(`TOTAL home: ${Date.now() - t0}ms`);
  }, 120_000);

  test('measure login page load time', async () => {
    const t0 = Date.now();

    await browser.open(`${TARGET_URL}/login`);
    const tOpen = Date.now();
    console.log(`2-open: ${tOpen - t0}ms`);

    await browser.waitForFlutter(90_000);
    const tFlutter = Date.now();
    console.log(`2-flutter-ready: ${tFlutter - t0}ms`);

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const tSnapshot = Date.now();
    console.log(`2-snapshot: ${tSnapshot - t0}ms (${snap.refs.length} refs)`);

    expect(snap.refs.length).toBeGreaterThan(0);
    console.log(`TOTAL login: ${Date.now() - t0}ms`);
  }, 120_000);
});
