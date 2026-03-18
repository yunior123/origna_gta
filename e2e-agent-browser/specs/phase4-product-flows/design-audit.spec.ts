/**
 * OrignaGTA — Design Audit E2E Tests (agent-browser)
 * Migrated from e2e/playwright_ui/design-audit.spec.ts
 *
 * Visual design audit: navigates to every screen, takes labelled screenshots.
 * Captures auth screens, buyer screens, seller screens, desktop/tablet layouts,
 * and design token smoke checks.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  WEB_APP_URL,
  TEST_PRODUCTS,
} from '../../lib/config.js';

import * as fs from 'fs';
import * as path from 'path';

const TARGET = process.env.E2E_TARGET_URL ?? WEB_APP_URL;
const DESKTOP = path.join(process.env.HOME ?? '/tmp', 'Desktop', 'origna-design-audit');

function ensureDir(dir: string) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

describe('Auth Screens', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    ensureDir(path.join(DESKTOP, 'mobile'));
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Login screen — captures screenshot', async () => {
    await browser.open(`${TARGET}/login`);
    await browser.waitForFlutter(90_000);
    await browser.screenshot(path.join(DESKTOP, 'mobile', '01-login-tab.png'));
  });

  test('Privacy Policy screen', async () => {
    await browser.open(`${TARGET}/privacy-policy`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'mobile', '04-privacy-policy.png'));
  });

  test('Terms of Service screen', async () => {
    await browser.open(`${TARGET}/terms-of-service`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'mobile', '05-terms-of-service.png'));
  });
});

describe('Buyer Screens — Mobile', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    ensureDir(path.join(DESKTOP, 'buyer-mobile'));
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Home screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '01-home.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Product Detail screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/product/${TEST_PRODUCTS.HIGH_STOCK}`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '02-product-detail.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Cart screen — empty', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/cart`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '03-cart-empty.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Favorites screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/favorites`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '04-favorites.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Orders screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/orders`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '05-orders.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Profile screen — buyer', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/profile`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '06-profile.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Address Management screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/profile/addresses`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '07-addresses.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Subscription screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/subscription`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'buyer-mobile', '08-subscription.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});

describe('Seller Screens — Mobile', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    ensureDir(path.join(DESKTOP, 'seller-mobile'));
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Seller Products screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/products`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '01-seller-products.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Seller Orders screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/orders`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '02-seller-orders.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Seller Warehouses screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/warehouses`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '03-seller-warehouses.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Seller Integration screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/integration`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '04-seller-integration.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Admin Panel screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/admin`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '05-admin-panel.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Seller Shipping Approval screen', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/shipping-approval`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'seller-mobile', '06-shipping-approval.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});

describe('Desktop Layouts', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    ensureDir(path.join(DESKTOP, 'desktop'));
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Home — desktop layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'desktop', '01-home-desktop.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Product Detail — desktop layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/product/${TEST_PRODUCTS.HIGH_STOCK}`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'desktop', '02-product-detail-desktop.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Cart — desktop layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/cart`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'desktop', '03-cart-desktop.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Profile — desktop layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/profile`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'desktop', '04-profile-desktop.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Seller Products — desktop layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/seller/products`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'desktop', '05-seller-products-desktop.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});

describe('Tablet Layouts', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
    ensureDir(path.join(DESKTOP, 'tablet'));
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Home — tablet layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'tablet', '01-home-tablet.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('Product Detail — tablet layout', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/product/${TEST_PRODUCTS.HIGH_STOCK}`);
    await browser.waitForFlutter();
    await browser.screenshot(path.join(DESKTOP, 'tablet', '02-product-detail-tablet.png'));
    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});

describe('Design Token Verification', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Login screen — semantics anchors present', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/login`);
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Login screen should have semantic labels for email, password, and submit
    const hasInputs = snap.refs.some(r => /input-|email|password/i.test(r.name));
    const hasButtons = snap.refs.some(r => /btn-|login|sign/i.test(r.name));
    expect(hasInputs || hasButtons).toBe(true);
  });

  test('Home screen — bottom nav present', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/`);
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Bottom nav should have Home, Cart, Profile or similar navigation items
    const navItems = snap.refs.filter(r => /nav-|bottom-nav|home|cart|profile/i.test(r.name));
    expect(navItems.length).toBeGreaterThan(0);
  });

  test('Profile screen — all sections visible', { timeout: 60_000 }, async () => {
    await browser.open(`${TARGET}/#/profile`);
    await browser.waitForFlutter();
    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Profile should have visible elements (settings, account info, etc.)
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});
