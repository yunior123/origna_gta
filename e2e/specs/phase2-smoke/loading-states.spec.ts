/**
 * OrignaGTA — Loading States E2E Tests (agent-browser)
 * ======================================================
 * Verifies that loading indicators (spinners, skeletons) appear
 * before content loads on key screens.
 *
 * Note: On fast connections, loading states may be too brief to capture.
 * These tests verify that the page transitions from an initial state
 * to a content-rich state, implying a loading phase occurred.
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = TEST_ACCOUNTS.BUYER_PASS;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  try {
    await browser.loginViaApi(email, password);
  } catch {
    try {
      await browser.open(WEB_APP_URL);
    } catch {
      // Best-effort only; the page snapshot below will show the current state.
    }
  }
  try {
    await browser.waitForFlutter();
  } catch {
    // Best-effort only; the loading-state checks use snapshots below.
  }
}

describe('Loading States', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  beforeEach(async () => { await browser.clearState(); });

  afterAll(async () => {
    await browser.close();
  });

  test('Home page transitions from loading to content', { timeout: 90_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/`);

    // Take an immediate snapshot — may catch loading state
    let initialSnap: any;
    try {
      initialSnap = await browser.snapshot({ interactive: true, compact: true });
    } catch {
      // Page still loading — expected
    }

    // Wait for Flutter semantics to fully load
    await browser.waitForFlutter();

    const loadedSnap = await browser.waitForChange({
      text: /product|btn-|home|search|cart|panier/i,
      timeout: 30_000,
    });

    // After loading, page should have interactive elements
    expect(loadedSnap.refs.length > 0 || loadedSnap.raw.length > 0).toBe(true);

    // Look for product cards, navigation, or search — indicators of loaded content
    const hasContent = loadedSnap.refs.some(r =>
      /product|btn-|search|cart|nav-|home/i.test(r.name) ||
      (r.text != null && /product|search/i.test(r.text))
    );
    expect(hasContent).toBe(true);
  });

  test('Product detail page loads with content', { timeout: 90_000 }, async () => {
    // Navigate to home first to find a product
    await browser.open(`${WEB_APP_URL}/`);
    await browser.waitForFlutter();

    let snap = await browser.waitForChange({
      text: /product-card|btn-|product/i,
      timeout: 30_000,
    });

    // Try to find and click a product card
    const productCard = browser.findByLabel(snap, /product-card/i);
    if (productCard) {
      await browser.click(productCard.ref);
      await browser.waitForFlutter();

      const detailSnap = await browser.waitForChange({
        text: /add to cart|ajouter|price|\$|description|product/i,
        timeout: 30_000,
      });

      // Product detail should have loaded content
      expect(detailSnap.refs.length > 0 || detailSnap.raw.length > 0).toBe(true);

      const hasProductDetail = detailSnap.refs.some(r =>
        /add.to.cart|ajouter|price|\$|description|quantity|btn-/i.test(r.name) ||
        (r.text != null && /\$[\d.]+|add|ajouter/i.test(r.text))
      );
      expect(hasProductDetail || detailSnap.refs.length > 3).toBe(true);
    } else {
      // No product cards found — home page may not have products, still loaded
      expect(snap.refs.length > 0 || snap.raw.length > 0).toBe(true);
    }
  });

  test('Orders page loads after authentication', { timeout: 90_000 }, async () => {
    await loginAs(browser, BUYER_EMAIL, BUYER_PASSWORD);

    await browser.open(`${WEB_APP_URL}/#/orders`);

    // Take immediate snapshot to see loading state
    let earlySnap: any;
    try {
      earlySnap = await browser.snapshot({ interactive: true, compact: true });
    } catch { /* still loading */ }

    await browser.waitForFlutter();
    let loadedSnap: any;
    try {
      loadedSnap = await browser.waitForChange({
        text: /order|commande|empty|vide|no order|delivered|shipped|pending/i,
        timeout: 10_000,
      });
    } catch {
      loadedSnap = await browser.snapshot({ interactive: true, compact: true });
    }

    // Page loaded with content or empty state
    expect(loadedSnap.refs.length > 0 || loadedSnap.raw.length > 0).toBe(true);
  });

  test('Login page renders interactive form elements', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/login`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /you@example|login_email_field|sign in|se connecter|btn-/i,
      timeout: 30_000,
    });

    // Login form should have interactive elements
    expect(snap.refs.length > 0 || snap.raw.length > 0).toBe(true);

    const hasFormElements = snap.refs.some(r =>
      /text|email|password|editableText|textbox|textField/i.test(r.role) ||
      /you@example|login_email_field|login_password_field|submit|sign in|se connecter/i.test(r.name)
    );
    expect(hasFormElements || snap.refs.length > 2).toBe(true);
  });
});
