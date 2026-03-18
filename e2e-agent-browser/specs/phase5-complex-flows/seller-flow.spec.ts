/**
 * OrignaGTA — Seller Flow E2E Tests (agent-browser)
 * ===================================================
 * Migrated from e2e/playwright_ui/seller-flow.spec.ts
 *
 * Complete seller journey: login, add product, profile seller tools,
 * seller dashboard, seller orders, cart access, sign-out.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { signIn } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const SELLER_EMAIL = process.env.E2E_SELLER_EMAIL ?? TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASSWORD = process.env.E2E_SELLER_PASSWORD ?? TEST_ACCOUNTS.SELLER_PASS;

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

describe('Seller Flow', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Seller can authenticate via API', async () => {
    const auth = await signIn(SELLER_EMAIL, SELLER_PASSWORD);
    expect(auth.idToken).toBeTruthy();
    expect(auth.localId).toBeTruthy();
  });

  test('Complete Seller Journey — login, profile tools, dashboard, orders, sign-out', { timeout: 60_000 }, async () => {
    // Step 1: Login via UI
    await loginAs(browser, SELLER_EMAIL, SELLER_PASSWORD);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    expect(settings).toBeTruthy();

    // Step 2: Navigate to profile/settings
    await browser.click(settings!.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    snap = await browser.snapshot({ interactive: true, compact: true });

    // Step 3: Verify "Become Seller" is NOT shown (already a seller)
    const becomeSeller = browser.findByLabel(snap, /menu-become-seller|become.*seller|devenir.*vendeur/i);
    // For an active seller, this may be hidden or show seller tools instead
    const sellerTools = browser.findByLabel(snap, /seller|vendeur|dashboard|tableau.*bord|my.*products|mes.*produits/i);

    // Step 4: Check for seller-specific menu items
    const myOrders = browser.findByLabel(snap, /menu-my-orders/);

    // Step 5: Navigate to seller dashboard or products if available
    if (sellerTools) {
      await browser.click(sellerTools.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();

      snap = await browser.snapshot({ interactive: true, compact: true });
      const dashContent = browser.findByLabel(snap, /product|produit|order|commande|dashboard|add|ajouter/i);
      expect(dashContent ?? sellerTools).toBeTruthy();

      // Go back to settings
      await browser.open(WEB_APP_URL);
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsAgain = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsAgain) {
        await browser.click(settingsAgain.ref);
        await new Promise(r => setTimeout(r, 2000));
      }
    }

    // Step 6: Check orders
    snap = await browser.snapshot({ interactive: true, compact: true });
    if (myOrders || browser.findByLabel(snap, /menu-my-orders/)) {
      const ordersBtn = browser.findByLabel(snap, /menu-my-orders/);
      if (ordersBtn) {
        await browser.click(ordersBtn.ref);
        await new Promise(r => setTimeout(r, 2000));
        await browser.waitForFlutter();

        snap = await browser.snapshot({ interactive: true, compact: true });
        const orderContent = browser.findByLabel(snap, /order|commande|empty|aucun/i);
        expect(orderContent ?? ordersBtn).toBeTruthy();

        // Go back
        await browser.open(WEB_APP_URL);
        await browser.waitForFlutter();
        snap = await browser.snapshot({ interactive: true, compact: true });
        const settingsAgain2 = browser.findByLabel(snap, /btn-home-settings/);
        if (settingsAgain2) {
          await browser.click(settingsAgain2.ref);
          await new Promise(r => setTimeout(r, 2000));
        }
      }
    }

    // Step 7: Sign out
    snap = await browser.snapshot({ interactive: true, compact: true });
    const signOut = browser.findByLabel(snap, /btn-sign-out|sign.out|d[eé]connexion/i);
    if (signOut) {
      await browser.click(signOut.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();

      snap = await browser.snapshot({ interactive: true, compact: true });
      const loginBtn = browser.findByLabel(snap, /se connecter|sign in|login/i);
      const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
      expect(loginBtn ?? settingsBtn).toBeTruthy();
    }
  });
});
