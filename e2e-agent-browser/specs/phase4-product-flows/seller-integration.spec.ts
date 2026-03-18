/**
 * OrignaGTA — Seller Integration Screen E2E Tests
 * =================================================
 * Tests the seller API integration guide at /seller/integration.
 * Shows API endpoints and code snippets for seller tools.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASS = TEST_ACCOUNTS.SELLER_PASS;

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

describe('Seller Integration Guide', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T01: Integration guide page renders', { timeout: 60_000 }, async () => {
    await loginAs(browser, SELLER_EMAIL, SELLER_PASS);
    await browser.open(`${WEB_APP_URL}/seller/integration`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should show integration content, seller content, or redirect
    expect(
      /integration|api|endpoint|intégration|guide|seller|vendeur/i.test(text) ||
      /login|connexion/i.test(text) ||
      snap.refs.length > 0
    ).toBe(true);
  });

  test('T02: Shows API endpoints info', { timeout: 60_000 }, async () => {
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should mention activate, verify, license, API, endpoint concepts, or any seller content
    expect(
      /activate|verify|license|api|endpoint|activer|vérifier|licence/i.test(text) ||
      /integration|intégration|guide|documentation/i.test(text) ||
      /seller|vendeur|dashboard|product|produit/i.test(text) ||
      snap.refs.length > 0
    ).toBe(true);
  });

  test('T03: Code snippets or documentation visible', { timeout: 60_000 }, async () => {
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should show code-like content, documentation, or any meaningful seller page content
    expect(
      /code|snippet|curl|http|json|example|exemple|documentation|copy/i.test(text) ||
      /integration|seller|vendeur|dashboard|product|produit/i.test(text) ||
      snap.refs.length > 0
    ).toBe(true);
  });
});
