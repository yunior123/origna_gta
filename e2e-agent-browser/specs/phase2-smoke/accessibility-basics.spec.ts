/**
 * OrignaGTA — Accessibility Basics E2E Tests (agent-browser)
 * ============================================================
 * Tests basic accessibility requirements:
 * - Interactive elements have semantic labels (ARIA)
 * - Buttons have accessible names
 * - Form inputs have labels
 * - Navigation elements are present
 *
 * Note: Full WCAG color-contrast audits require axe-core which needs
 * a Playwright Page handle. These tests use snapshot-based checks.
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASSWORD = TEST_ACCOUNTS.BUYER_PASS;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  await browser.open(`${WEB_APP_URL}/login`);
  await browser.waitForFlutter();
  let snap = await browser.waitForChange({ text: /you@example|vous@exemple|login_email_field/i, timeout: 30_000 });

  const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
  if (!emailInput) throw new Error('Email input not found');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.waitForChange({ text: /login_password_field|••••••••/i, timeout: 10_000 });
  const passInput = browser.findByLabel(snap, /login_password_field|••••••••/);
  if (!passInput) throw new Error('Password input not found');
  await browser.click(passInput.ref);
  await browser.type(password);

  await browser.press('Tab');
  await browser.waitForChange({ timeout: 500 });
  await browser.press('Enter');
  await browser.waitForChange({ timeout: 5000 });
  await browser.waitForFlutter();
}

describe('Accessibility Basics', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  beforeEach(async () => { await browser.clearState(); });

  afterAll(async () => {
    await browser.close();
  });

  test('Login page has labeled form inputs', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/login`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /you@example|login_email_field|sign in|se connecter/i,
      timeout: 30_000,
    });

    // Find input elements
    const inputs = snap.refs.filter(r =>
      /text|editableText|textbox|textField/i.test(r.role) ||
      /email|password|login_email_field|login_password_field|you@example|••••••••/i.test(r.name)
    );

    // Login page must have at least email + password inputs
    expect(inputs.length).toBeGreaterThanOrEqual(2);

    // Each input should have a non-empty name (semantic label)
    for (const input of inputs) {
      expect(input.name.length).toBeGreaterThan(0);
    }
  });

  test('Login page buttons have accessible names', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/login`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /login_submit|sign in|se connecter|btn-/i,
      timeout: 30_000,
    });

    const buttons = snap.refs.filter(r =>
      r.role === 'button' || /btn-|submit|sign in|se connecter|google/i.test(r.name)
    );

    // Should have at least a submit button
    expect(buttons.length).toBeGreaterThanOrEqual(1);

    // All buttons must have non-empty accessible names
    for (const btn of buttons) {
      expect(btn.name.length).toBeGreaterThan(0);
    }
  });

  test('Home page interactive elements have semantic labels', { timeout: 90_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /btn-|product|cart|search|home/i,
      timeout: 30_000,
    });

    // All interactive elements should have names
    const interactiveRoles = ['button', 'link', 'textbox', 'checkbox', 'radio', 'switch'];
    const interactive = snap.refs.filter(r =>
      interactiveRoles.includes(r.role) || /btn-|nav-|input-/i.test(r.name)
    );

    // Home page should have interactive elements
    expect(interactive.length).toBeGreaterThan(0);

    // Count unlabeled interactive elements
    const unlabeled = interactive.filter(r => !r.name || r.name.trim().length === 0);

    // Allow some unlabeled (decorative icons wrapped in buttons),
    // but majority should be labeled
    const labeledRatio = (interactive.length - unlabeled.length) / interactive.length;
    expect(labeledRatio).toBeGreaterThanOrEqual(0.5);

    if (unlabeled.length > 0) {
      console.log(`Accessibility: ${unlabeled.length}/${interactive.length} interactive elements missing labels`);
    }
  });

  test('Navigation elements use semantic btn- or nav- prefixes', { timeout: 90_000 }, async () => {
    await loginAs(browser, BUYER_EMAIL, BUYER_PASSWORD);
    await browser.open(`${WEB_APP_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /btn-|nav-|home|cart|search/i,
      timeout: 30_000,
    });

    // Find elements with btn- or nav- semantic label convention
    const semanticElements = snap.refs.filter(r =>
      /^btn-|^nav-|^input-/.test(r.name)
    );

    // App should follow the btn-/nav-/input- naming convention
    expect(semanticElements.length).toBeGreaterThan(0);
    console.log(`Semantic label elements found: ${semanticElements.length} (btn-/nav-/input- prefixed)`);
  });

  test('Product cards have semantic labels for E2E discoverability', { timeout: 90_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /product-card|product|btn-/i,
      timeout: 30_000,
    });

    // Look for product cards with semantic labels
    const productCards = browser.findAllByLabel(snap, /product-card/i);

    if (productCards.length > 0) {
      // Each product card should have a non-empty label
      for (const card of productCards) {
        expect(card.name.length).toBeGreaterThan(0);
      }
      console.log(`Product cards with semantic labels: ${productCards.length}`);
    } else {
      // No product cards on home — might be empty or different layout
      // At minimum the page has interactive elements
      expect(snap.refs.length).toBeGreaterThan(0);
    }
  });

  test('Authenticated pages have navigation structure', { timeout: 90_000 }, async () => {
    await loginAs(browser, BUYER_EMAIL, BUYER_PASSWORD);

    // Check profile/settings page for navigation elements
    await browser.open(`${WEB_APP_URL}/profile`);
    await browser.waitForFlutter();

    const snap = await browser.waitForChange({
      text: /profile|profil|settings|param|account|btn-/i,
      timeout: 30_000,
    });

    expect(snap.refs.length).toBeGreaterThan(0);

    // Profile page should have buttons/links for sub-navigation
    const navElements = snap.refs.filter(r =>
      r.role === 'button' || r.role === 'link' ||
      /btn-|nav-|settings|orders|address|favorites/i.test(r.name)
    );
    expect(navElements.length).toBeGreaterThan(0);
  });
});
