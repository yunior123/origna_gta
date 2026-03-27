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

async function authenticate(browser: AgentBrowser): Promise<void> {
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(4_000);
  runAgentBrowser([
    'eval',
    `(async()=>{const r=await fetch('https://api.dev.orignagta.ca/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'e2e-admin@test.origna.ca',password:'REDACTED_TEST_PASSWORD'})});const d=await r.json();localStorage.setItem('orignabase_access_token',d.access_token);localStorage.setItem('orignabase_refresh_token',d.refresh_token);localStorage.setItem('orignabase_email','e2e-admin@test.origna.ca');return JSON.stringify({ok:!!d.access_token,userId:d.user?.id})})()`,
  ]);
  await browser.open('https://dev.orignagta.ca', 60_000);
  await sleep(6_000);
  await browser.snapshot({ interactive: true, compact: true });
}

async function capture(browser: AgentBrowser, name: string): Promise<void> {
  const path = join(OUT_DIR, name);
  await browser.screenshot(path);
  console.log(`captured ${name}`);
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

  for (let i = 0; i < scrollAttempts; i += 1) {
    await browser.scrollAndWait('up', 2_000).catch(() => undefined);
  }

  return false;
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

async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = new AgentBrowser();

  await authenticate(browser);
  await setViewport(1440, 900);

  await goHome(browser);
  await browser.safeClick(/btn-home-sort/i);
  await capture(browser, '165-home-sort-active.png');
  await browser.safeClick(/btn-home-price-filter/i);
  await capture(browser, '166-home-price-filter-active.png');
  await capture(browser, '143-modern-product-card.png');
  await capture(browser, '153-promo-banner.png');

  await browser.safeClick(/btn-add-product/i);
  await sleep(4_000);
  await capture(browser, '138-addproduct-food-info.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '139-addproduct-delivery.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '140-addproduct-package.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '141-addproduct-specs.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '142-addproduct-supplier.png');

  await goHome(browser);
  await safeClickSearch(browser, /btn-edit-product-/i, 2);
  await capture(browser, '105-edit-product-top.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '106-edit-product-media.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '107-edit-product-shipping.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '108-edit-product-location.png');

  await goProfile(browser);
  await capture(browser, '167-profile-header-card.png');

  await browser.safeClick(/menu-favorites/i);
  await sleep(3_000);
  await capture(browser, '159-favorites-empty.png');

  await goProfile(browser);
  await browser.safeClick(/menu-address/i);
  await sleep(3_000);
  await capture(browser, '112-seller-warehouses-list.png');
  await safeClickSearch(browser, /add|edit|address/i, 3);
  await capture(browser, '128-address-edit-form.png');

  await goProfile(browser);
  await browser.safeClick(/menu-my-messages/i);
  await sleep(3_000);
  await capture(browser, '164-chat-empty.png');
  await safeClickSearch(browser, /chat-thread-/i, 3);
  await capture(browser, '127-chat-conversation.png');

  await goProfile(browser);
  await browser.safeClick(/menu-premium/i);
  await sleep(3_000);
  await capture(browser, '129-subscription-cancel-flow.png');
  await safeClickSearch(browser, /cancel-subscription|btn-cancel-subscription/i, 2);
  await capture(browser, '130-subscription-success.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-orders/i);
  await sleep(4_000);
  await capture(browser, '162-seller-orders-populated.png');
  await capture(browser, '156-mark-shipped-dialog.png');
  await capture(browser, '157-update-shipping-dialog.png');

  await goProfile(browser);
  await browser.safeClick(/menu-seller-dashboard/i);
  await sleep(4_000);
  await capture(browser, '163-seller-products-populated.png');

  await goProfile(browser);
  await browser.safeClick(/menu-admin-panel/i);
  await sleep(4_000);
  await capture(browser, '168-admin-users-tab.png');
  await browser.safeClick(/admin-tab-orders|admin_tab_orders/i);
  await sleep(2_500);
  await capture(browser, '169-admin-orders-tab.png');
  await browser.safeClick(/admin-tab-products|admin_tab_products/i);
  await sleep(2_500);
  await capture(browser, '170-admin-products-tab.png');

  await goHome(browser);
  await browser.safeClick(/btn-cart/i);
  await sleep(4_000);
  await capture(browser, '144-cart-total-breakdown.png');
  await capture(browser, '145-free-shipping-progress.png');
  await safeClickSearch(browser, /checkout|place order|btn-checkout/i, 2);
  await capture(browser, '095-checkout-address-section.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '096-checkout-items-section.png');
  await browser.scrollAndWait('down', 2_000).catch(() => undefined);
  await capture(browser, '097-checkout-payment-section.png');

  await capture(browser, '171-home-default-desktop.png');
  await goProfile(browser);
  await capture(browser, '172-profile-menu-desktop.png');
  await goHome(browser);
  await capture(browser, '173-home-categories-desktop.png');
  await goProfile(browser);
  await browser.safeClick(/menu-language/i);
  await sleep(2_000);
  await capture(browser, '152-language-selector.png');
}

await main();
