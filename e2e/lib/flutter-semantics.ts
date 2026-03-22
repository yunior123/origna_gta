/**
 * Flutter Web Semantics Helpers for agent-browser
 * Bilingual (EN/FR) selector patterns for OrignaGTA
 */
import { AgentBrowser } from './agent-browser.js';
import type { Snapshot, SnapshotRef } from './types.js';

// Bilingual patterns for common UI elements
export const BTN_SETTINGS = /btn-home-settings/;
export const BTN_SIGN_IN = /sign\s*in|se\s*connecter|connexion/i;
export const BTN_CART = /cart|shopping|panier/i;
export const BTN_ADD_PRODUCT = /add\s*product|ajouter/i;
export const BTN_SIGN_OUT = /btn-sign-out/;
export const INPUT_SEARCH = /input-home-search/;
export const INPUT_EMAIL = /you@example|vous@exemple/i;
export const INPUT_PASSWORD = /••••••••/;
export const BTN_LOGIN_SUBMIT = /login_submit_button/;

/**
 * Login via the Flutter UI using agent-browser.
 */
export async function loginViaUI(
  browser: AgentBrowser,
  email: string,
  password: string,
): Promise<void> {
  // Click settings
  let snap = await browser.snapshot({ interactive: true, compact: true });
  const settingsBtn = browser.findByLabel(snap, BTN_SETTINGS);
  if (!settingsBtn) throw new Error('Settings button not found');
  await browser.click(settingsBtn.ref);

  // Wait for login option to appear (polls every 200ms instead of fixed 1.5s sleep)
  snap = await browser.waitForChange({ text: BTN_SIGN_IN, timeout: 5_000 });
  const loginBtn = browser.findByLabel(snap, BTN_SIGN_IN);
  if (!loginBtn) throw new Error('Sign in button not found');
  await browser.click(loginBtn.ref);

  // Wait for login form (polls every 200ms instead of fixed 2s sleep)
  snap = await browser.waitForChange({ text: INPUT_EMAIL, timeout: 5_000 });

  // Fill email
  const emailInput = browser.findByLabel(snap, INPUT_EMAIL);
  if (!emailInput) throw new Error('Email input not found');
  await browser.fill(emailInput.ref, email);

  // Fill password
  const passInput = browser.findByLabel(snap, INPUT_PASSWORD);
  if (!passInput) throw new Error('Password input not found');
  await browser.fill(passInput.ref, password);

  // Click login
  const submitBtn = browser.findByLabel(snap, BTN_LOGIN_SUBMIT);
  if (!submitBtn) throw new Error('Login submit button not found');
  await browser.click(submitBtn.ref);

  // Wait for navigation back to home (polls instead of fixed 3s sleep)
  await browser.waitForChange({ text: BTN_SETTINGS, timeout: 10_000 });
}

/**
 * Check if user is logged in by looking for sign-out button in settings.
 */
export async function isLoggedIn(browser: AgentBrowser): Promise<boolean> {
  const snap = await browser.snapshot({ interactive: true, compact: true });
  return browser.findByLabel(snap, BTN_SIGN_OUT) !== null;
}

/**
 * Navigate to settings menu and check for authenticated menu items.
 */
export async function openSettings(browser: AgentBrowser): Promise<Snapshot> {
  let snap = await browser.snapshot({ interactive: true, compact: true });
  const settingsBtn = browser.findByLabel(snap, BTN_SETTINGS);
  if (settingsBtn) {
    await browser.click(settingsBtn.ref);
    // Poll for settings menu to render instead of fixed 1.5s sleep
    snap = await browser.waitForChange({ minRefs: (snap.refs.length + 1), timeout: 5_000 });
  }
  return snap;
}

/**
 * Fill a Stripe Checkout form via agent-browser.
 */
export async function fillStripeCheckout(
  browser: AgentBrowser,
  card = { number: '4242424242424242', exp: '12/34', cvc: '123', name: 'Test Buyer', email: '' },
): Promise<void> {
  const snap = await browser.snapshot({ interactive: true, compact: true });

  if (card.email) {
    const emailField = browser.findByLabel(snap, /e-?mail/i);
    if (emailField) await browser.fill(emailField.ref, card.email);
  }

  const cardField = browser.findByLabel(snap, /card number|numéro de carte/i);
  const expField = browser.findByLabel(snap, /expir/i);
  const cvcField = browser.findByLabel(snap, /cvc|security|sécurité/i);
  const nameField = browser.findByLabel(snap, /cardholder|titulaire/i);

  if (cardField) await browser.fill(cardField.ref, card.number);
  if (expField) await browser.fill(expField.ref, card.exp);
  if (cvcField) await browser.fill(cvcField.ref, card.cvc);
  if (nameField) await browser.fill(nameField.ref, card.name);
}

/**
 * Click the Pay/Submit button on Stripe Checkout.
 */
export async function clickStripePay(browser: AgentBrowser): Promise<void> {
  const snap = await browser.snapshot({ interactive: true, compact: true });
  const payBtn = browser.findByRole(snap, 'button', /pay|payer|submit/i);
  if (!payBtn) throw new Error('Stripe Pay button not found in snapshot');
  await browser.click(payBtn.ref);
}

/**
 * Find a product card by product ID in the home page snapshot.
 */
export function findProductCard(snap: Snapshot, browser: AgentBrowser, productId: string): SnapshotRef | null {
  return browser.findByLabel(snap, new RegExp(`product-card-${productId}`));
}

/**
 * Find add-to-cart button for a specific product.
 */
export function findAddToCartButton(snap: Snapshot, browser: AgentBrowser, productId: string): SnapshotRef | null {
  return browser.findByLabel(snap, new RegExp(`btn-add-to-cart-${productId}`));
}
