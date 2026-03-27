#!/usr/bin/env bun

import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser } from './agent-browser.js';

const OUT_DIR =
  '/Users/yuniorrodriguezosorio/Desktop/origna-design-review-2026-03-26';

function runAgentBrowser(args: string[], timeout = 30_000): string {
  const result = Bun.spawnSync(['agent-browser', ...args], {
    env: process.env,
    timeout,
  });
  if (result.exitCode !== 0) {
    throw new Error(
      `agent-browser ${args[0]} failed: ${
        result.stderr.toString().trim() || result.stdout.toString().trim()
      }`,
    );
  }
  return result.stdout.toString();
}

async function sleep(ms: number): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, ms));
}

async function setViewport(width: number, height: number): Promise<void> {
  runAgentBrowser(['set', 'viewport', String(width), String(height)]);
  await sleep(800);
}

async function capture(browser: AgentBrowser, name: string): Promise<void> {
  await browser.screenshot(join(OUT_DIR, name));
  console.log(`captured ${name}`);
}

async function authenticate(browser: AgentBrowser): Promise<void> {
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(4_000);
  runAgentBrowser([
    'eval',
    `(async()=>{const r=await fetch('https://api.dev.orignagta.ca/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'e2e-admin@test.origna.ca',password:'REDACTED_TEST_PASSWORD'})});const d=await r.json();localStorage.setItem('orignabase_access_token',d.access_token);localStorage.setItem('orignabase_refresh_token',d.refresh_token);localStorage.setItem('orignabase_email','e2e-admin@test.origna.ca');return JSON.stringify({ok:!!d.access_token,userId:d.user?.id})})()`,
  ]);
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(6_000);
}

async function goHome(browser: AgentBrowser): Promise<void> {
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(4_000);
}

async function goProfile(browser: AgentBrowser): Promise<void> {
  await goHome(browser);
  await browser.safeClick(/btn-home-settings/i);
  await sleep(3_000);
}

async function safeClickSearch(
  browser: AgentBrowser,
  pattern: RegExp,
  scrollAttempts = 4,
): Promise<boolean> {
  for (let i = 0; i < scrollAttempts; i += 1) {
    const ok = await browser.safeClick(pattern).catch(() => false);
    if (ok) {
      await sleep(2_500);
      return true;
    }
    await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  }
  return false;
}

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = new AgentBrowser();
  await authenticate(browser);

  await setViewport(390, 844);
  await goHome(browser);
  await capture(browser, '174-home-mobile-authenticated.png');
  await browser.safeClick(/btn-home-sort/i);
  await capture(browser, '175-home-sort-mobile.png');
  await browser.safeClick(/btn-home-price-filter/i);
  await capture(browser, '176-home-price-filter-mobile.png');

  await browser.safeClick(/btn-add-product/i);
  await sleep(4_000);
  await capture(browser, '177-addproduct-top-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '178-addproduct-mid-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '179-addproduct-bottom-mobile.png');

  await goHome(browser);
  await safeClickSearch(browser, /btn-edit-product-/i, 2);
  await capture(browser, '180-editproduct-top-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '181-editproduct-mid-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '182-editproduct-bottom-mobile.png');

  await goProfile(browser);
  await capture(browser, '183-profile-mobile-menu.png');
  await browser.safeClick(/menu-favorites/i);
  await sleep(3_000);
  await capture(browser, '184-favorites-empty-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-address/i);
  await sleep(3_000);
  await capture(browser, '185-addresses-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-my-messages/i);
  await sleep(3_000);
  await capture(browser, '186-chat-inbox-mobile.png');
  await safeClickSearch(browser, /chat-thread-/i, 3);
  await capture(browser, '187-chat-thread-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-premium/i);
  await sleep(3_000);
  await capture(browser, '188-subscription-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-orders/i);
  await sleep(4_000);
  await capture(browser, '189-seller-orders-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-dashboard/i);
  await sleep(4_000);
  await capture(browser, '190-seller-products-mobile.png');

  await goProfile(browser);
  await browser.safeClick(/menu-admin-panel/i);
  await sleep(4_000);
  await capture(browser, '191-admin-users-mobile.png');
  await browser.safeClick(/admin-tab-orders|admin_tab_orders/i);
  await sleep(2_500);
  await capture(browser, '192-admin-orders-mobile.png');
  await browser.safeClick(/admin-tab-products|admin_tab_products/i);
  await sleep(2_500);
  await capture(browser, '193-admin-products-mobile.png');

  await goHome(browser);
  await browser.safeClick(/btn-cart/i);
  await sleep(4_000);
  await capture(browser, '194-cart-mobile.png');
  await safeClickSearch(browser, /checkout|btn-checkout|place order/i, 2);
  await capture(browser, '195-checkout-top-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '196-checkout-mid-mobile.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '197-checkout-bottom-mobile.png');

  await setViewport(1440, 900);
  await goHome(browser);
  await capture(browser, '198-home-search-focus.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '199-home-scrolled-desktop.png');

  await goProfile(browser);
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '200-profile-scrolled-desktop.png');

  await browser.safeClick(/menu-address/i);
  await sleep(3_000);
  await capture(browser, '201-addresses-top-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '202-addresses-bottom-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-orders/i);
  await sleep(4_000);
  await capture(browser, '203-seller-orders-top-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '204-seller-orders-middle-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '205-seller-orders-bottom-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-dashboard/i);
  await sleep(4_000);
  await capture(browser, '206-seller-products-top-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '207-seller-products-middle-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '208-seller-products-bottom-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-admin-panel/i);
  await sleep(4_000);
  await capture(browser, '209-admin-users-top-desktop.png');
  await browser.safeClick(/admin-tab-orders|admin_tab_orders/i);
  await sleep(2_500);
  await capture(browser, '210-admin-orders-top-desktop.png');
  await browser.safeClick(/admin-tab-products|admin_tab_products/i);
  await sleep(2_500);
  await capture(browser, '211-admin-products-top-desktop.png');

  await goHome(browser);
  await browser.safeClick(/btn-cart/i);
  await sleep(4_000);
  await capture(browser, '212-cart-top-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '213-cart-bottom-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-my-messages/i);
  await sleep(3_000);
  await safeClickSearch(browser, /chat-thread-/i, 3);
  await capture(browser, '214-chat-thread-bottom-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-premium/i);
  await sleep(3_000);
  await capture(browser, '215-subscription-details-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-language/i);
  await sleep(2_000);
  await capture(browser, '216-language-selector-closeup.png');

  await goProfile(browser);
  await browser.safeClick(/menu-favorites/i);
  await sleep(3_000);
  await capture(browser, '217-favorites-empty-closeup.png');

  await goHome(browser);
  await capture(browser, '218-home-product-grid-closeup.png');

  await safeClickSearch(browser, /btn-edit-product-/i, 2);
  await capture(browser, '219-editproduct-images-panel-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '220-editproduct-inventory-panel-desktop.png');

  await goHome(browser);
  await browser.safeClick(/btn-add-product/i);
  await sleep(4_000);
  await capture(browser, '221-addproduct-shipping-options-desktop.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '222-addproduct-warehouse-selector-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-admin-panel/i);
  await sleep(4_000);
  await capture(browser, '223-admin-panel-overview-desktop.png');

  await goProfile(browser);
  await capture(browser, '224-profile-theme-switcher-desktop.png');

  await browser.safeClick(/menu-address/i);
  await sleep(3_000);
  await safeClickSearch(browser, /add|edit|address/i, 3);
  await capture(browser, '225-address-form-fields-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-my-messages/i);
  await sleep(3_000);
  await capture(browser, '226-chat-empty-state-desktop.png');
  await safeClickSearch(browser, /chat-thread-/i, 3);
  await capture(browser, '227-chat-thread-header-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-orders/i);
  await sleep(4_000);
  await capture(browser, '228-seller-orders-dialog-area-desktop.png');

  await goHome(browser);
  await browser.safeClick(/btn-cart/i);
  await sleep(4_000);
  await capture(browser, '229-cart-summary-sticky-desktop.png');
  await safeClickSearch(browser, /checkout|btn-checkout|place order/i, 2);
  await sleep(3_000);
  await capture(browser, '230-checkout-summary-bottom-desktop.png');

  await goHome(browser);
  await capture(browser, '231-home-category-chips-desktop.png');
  await goProfile(browser);
  await capture(browser, '232-profile-actions-desktop.png');

  await goProfile(browser);
  await browser.safeClick(/menu-admin-panel/i);
  await sleep(4_000);
  await capture(browser, '233-admin-tabstrip-desktop.png');
}

await main();
