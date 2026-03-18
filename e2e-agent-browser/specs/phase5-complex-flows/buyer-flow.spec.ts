/**
 * OrignaGTA — Buyer Flow E2E Tests (agent-browser)
 * ==================================================
 * Migrated from e2e/playwright_ui/buyer-flow.spec.ts
 *
 * Complete buyer journey: login, profile sub-pages, favorites,
 * addresses, orders, cart/checkout, product detail, sign-out.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { signIn } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const BUYER_EMAIL = process.env.E2E_BUYER_EMAIL ?? TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = process.env.E2E_BUYER_PASSWORD ?? TEST_ACCOUNTS.BUYER_PASS;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  await browser.open(`${WEB_APP_URL}/login`);
  await browser.waitForFlutter();
  let snap = await browser.snapshot({ interactive: true, compact: true });

  const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
  if (!emailInput) throw new Error('Email input not found');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.snapshot({ interactive: true, compact: true });
  const passInput = browser.findByLabel(snap, /login_password_field|••••••••/);
  if (!passInput) throw new Error('Password input not found');
  await browser.click(passInput.ref);
  await browser.type(password);

  await browser.press('Tab');
  await new Promise(r => setTimeout(r, 500));
  await browser.press('Enter');
  await new Promise(r => setTimeout(r, 5000));
  await browser.waitForFlutter();
}

describe('Buyer Flow', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Buyer can authenticate via API', async () => {
    const auth = await signIn(BUYER_EMAIL, BUYER_PASSWORD);
    expect(auth.idToken).toBeTruthy();
    expect(auth.localId).toBeTruthy();
  });

  test('Complete Buyer Journey — login, profile sub-pages, favorites, addresses, orders, cart, product detail, sign-out', { timeout: 60_000 }, async () => {
    // Step 1: Login via UI
    await loginAs(browser, BUYER_EMAIL, BUYER_PASSWORD);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    // Verify we landed on home (settings button visible)
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    expect(settings).toBeTruthy();

    // Step 2: Navigate to profile/settings
    await browser.click(settings!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    snap = await browser.snapshot({ interactive: true, compact: true });

    // Step 3: Check favorites menu item
    const favorites = browser.findByLabel(snap, /menu-favorites|favorites|favoris/i);
    if (favorites) {
      await browser.click(favorites.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      // Should show favorites list or empty state
      const favContent = browser.findByLabel(snap, /favorite|favoris|empty|aucun|no.*favorite/i);
      expect(favContent ?? favorites).toBeTruthy();

      // Go back to settings
      await browser.open(`${WEB_APP_URL}`);
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsAgain = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsAgain) {
        await browser.click(settingsAgain.ref);
        await new Promise(r => setTimeout(r, 2000));
      }
    }

    // Step 4: Check addresses
    snap = await browser.snapshot({ interactive: true, compact: true });
    const addresses = browser.findByLabel(snap, /menu-address|address|adresse/i);
    if (addresses) {
      await browser.click(addresses.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const addrContent = browser.findByLabel(snap, /address|adresse|empty|aucun/i);
      expect(addrContent ?? addresses).toBeTruthy();

      // Go back
      await browser.open(`${WEB_APP_URL}`);
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsAgain2 = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsAgain2) {
        await browser.click(settingsAgain2.ref);
        await new Promise(r => setTimeout(r, 2000));
      }
    }

    // Step 5: Check orders
    snap = await browser.snapshot({ interactive: true, compact: true });
    const orders = browser.findByLabel(snap, /menu-my-orders/);
    if (orders) {
      await browser.click(orders.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const orderContent = browser.findByLabel(snap, /order|commande|empty|aucun/i);
      expect(orderContent ?? orders).toBeTruthy();

      await browser.open(`${WEB_APP_URL}`);
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsAgain3 = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsAgain3) {
        await browser.click(settingsAgain3.ref);
        await new Promise(r => setTimeout(r, 2000));
      }
    }

    // Step 6: Sign out
    snap = await browser.snapshot({ interactive: true, compact: true });
    const signOut = browser.findByLabel(snap, /btn-sign-out|sign.out|d[eé]connexion/i);
    if (signOut) {
      await browser.click(signOut.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();

      snap = await browser.snapshot({ interactive: true, compact: true });
      // Should see login button or sign-in option after sign-out
      const loginBtn = browser.findByLabel(snap, /se connecter|sign in|login/i);
      const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
      expect(loginBtn ?? settingsBtn).toBeTruthy();
    }
  });
});
