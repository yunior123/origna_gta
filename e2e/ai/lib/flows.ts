/**
 * Screen/flow definitions for AI navigation.
 * Each flow defines a screen to analyze with its URL, auth requirements, and setup.
 */
import { AgentBrowser } from '../../lib/agent-browser.js';
import { AI_CONFIG } from '../config.js';
import type { Snapshot } from '../../lib/types.js';

export interface ScreenFlow {
  name: string;
  path: string;
  role?: 'guest' | 'buyer' | 'seller' | 'admin';
  description: string;
}

/**
 * Wait for Flutter to fully render — the app shows a loading screen with
 * just "Legal" links for ~3-5s before the real UI appears.
 */
async function waitForFullRender(browser: AgentBrowser, timeout = 15_000): Promise<void> {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try {
      const snap = await browser.snapshot({ interactive: true, compact: true });
      // Full render has product cards, search, or settings button
      const hasContent = snap.refs.some(r =>
        /product-card-|input-home-search|btn-home-settings|category-chip|btn-cart/i.test(r.name),
      );
      if (hasContent && snap.refs.length > 10) return;
    } catch { /* snapshot may fail during load */ }
    await new Promise(r => setTimeout(r, 1_000));
  }
  // Proceed anyway — app may be empty but still functional
}

/**
 * Login via the settings → sign-in flow.
 * The Flutter app doesn't have a /login route — login is a dialog triggered
 * from the settings menu on the home page.
 */
async function loginViaSettings(browser: AgentBrowser, role: 'buyer' | 'seller' | 'admin'): Promise<void> {
  const account = AI_CONFIG.accounts[role];
  const url = AI_CONFIG.targetUrl;

  // Clear state first for clean login
  await browser.clearState();

  // Navigate to home and wait for full render
  await browser.open(`${url}/`);
  await browser.waitForFlutter();
  await waitForFullRender(browser);

  // Click settings button (retry up to 3 times)
  let snap: any;
  let settingsBtn: any;
  for (let attempt = 0; attempt < 3; attempt++) {
    snap = await browser.snapshot({ interactive: true, compact: true });
    settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) break;
    await new Promise(r => setTimeout(r, 2_000));
  }
  if (!settingsBtn) throw new Error('Settings button not found on home page');
  await browser.click(settingsBtn.ref);
  await browser.waitForFlutter();
  await new Promise(r => setTimeout(r, 3_000));

  // Click "Se connecter" / "Sign in" (retry snapshot)
  for (let attempt = 0; attempt < 3; attempt++) {
    snap = await browser.snapshot({ interactive: true, compact: true });
    const signInBtn = browser.findByLabel(snap, /sign.*in|se.*connecter|connexion/i);
    if (signInBtn) {
      await browser.click(signInBtn.ref);
      await browser.waitForFlutter();
      await new Promise(r => setTimeout(r, 3_000));
      break;
    }
    // Check if already logged in (sign out button visible)
    const signOut = browser.findByLabel(snap, /sign.*out|déconnex|logout/i);
    if (signOut) return; // Already logged in
    await new Promise(r => setTimeout(r, 1_000));
    if (attempt === 2) throw new Error('Sign in button not found in settings menu');
  }

  // Fill login form — re-snapshot after form appears
  snap = await browser.snapshot({ interactive: true, compact: true });

  // Email
    const emailField = snap.refs.find((r: any) =>
      r.role === 'textbox' && (/login_email|vous@exemple|email/i.test(r.name) || /@/i.test(r.name)),
    );
  if (emailField) {
    await browser.fill(emailField.ref, account.email);
  } else {
    throw new Error('Could not find email input on login form');
  }

  // Password
  const passField = snap.refs.find((r: any) =>
    r.role === 'textbox' && (/login_password|••••|password/i.test(r.name)),
  );
  if (passField) {
    await browser.fill(passField.ref, account.pass);
  } else {
    throw new Error('Could not find password input on login form');
  }

  // Submit
  await browser.safeClick(/login_submit_button/);
  await browser.waitForFlutter();
  await new Promise(r => setTimeout(r, 3_000));

  // Close any remaining dialog (click outside or press Escape)
  try {
    await browser.press('Escape');
    await new Promise(r => setTimeout(r, 1_000));
  } catch { /* ignore */ }
}

export const SCREEN_FLOWS: ScreenFlow[] = [
  {
    name: 'home',
    path: '/',
    role: 'guest',
    description: 'Home page — product grid, search bar, category chips, navigation',
  },
  {
    name: 'login-dialog',
    path: '/',
    role: 'guest',
    description: 'Login dialog (via settings → sign in) — email/password, social auth',
  },
  {
    name: 'home-authenticated',
    path: '/',
    role: 'buyer',
    description: 'Authenticated home — personalized product grid, cart badge, settings',
  },
  {
    name: 'cart',
    path: '/cart',
    role: 'buyer',
    description: 'Shopping cart — item list, quantities, subtotal, checkout button',
  },
  {
    name: 'settings-profile',
    path: '/',
    role: 'buyer',
    description: 'Settings → profile menu — orders, favorites, addresses, language, sign out',
  },
  {
    name: 'seller-dashboard',
    path: '/',
    role: 'seller',
    description: 'Seller home — add product button, seller tools, order management',
  },
  {
    name: 'admin-panel',
    path: '/',
    role: 'admin',
    description: 'Admin home — admin tools, user management, platform controls',
  },
];

/**
 * Navigate to a screen flow, handling auth and setup.
 * Returns the snapshot ready for analysis.
 */
export async function navigateToScreen(
  browser: AgentBrowser,
  flow: ScreenFlow,
): Promise<Snapshot> {
  const url = `${AI_CONFIG.targetUrl}${flow.path}`;

  if (flow.role && flow.role !== 'guest') {
    // Authenticated flow: login first via settings menu
    await loginViaSettings(browser, flow.role as 'buyer' | 'seller' | 'admin');

    // Navigate to target page after login
    if (flow.path !== '/') {
      await browser.open(url);
      await browser.waitForFlutter();
      await waitForFullRender(browser);
    } else if (flow.name === 'settings-profile') {
      // Open settings menu after login
      await waitForFullRender(browser);
      const snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsBtn) {
        await browser.click(settingsBtn.ref);
        await browser.waitForFlutter();
        await new Promise(r => setTimeout(r, 2_000));
      }
    } else {
      // Already on home after login
      await waitForFullRender(browser);
    }
  } else if (flow.name === 'login-dialog') {
    // Show login dialog
    await browser.clearState();
    await browser.open(url);
    await browser.waitForFlutter();
    await waitForFullRender(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
    if (settingsBtn) {
      await browser.click(settingsBtn.ref);
      await browser.waitForFlutter();
      await new Promise(r => setTimeout(r, 2_000));

      snap = await browser.snapshot({ interactive: true, compact: true });
      const signInBtn = browser.findByLabel(snap, /sign.*in|se.*connecter|connexion/i);
      if (signInBtn) {
        await browser.click(signInBtn.ref);
        await browser.waitForFlutter();
        await new Promise(r => setTimeout(r, 2_000));
      }
    }
  } else {
    // Guest flow
    await browser.clearState();
    await browser.open(url);
    await browser.waitForFlutter();
    await waitForFullRender(browser);
  }

  return browser.snapshot({ interactive: true, compact: true });
}

/**
 * Take a screenshot and return as base64 PNG.
 */
export async function captureScreenshot(browser: AgentBrowser, name: string): Promise<string> {
  const tmpPath = `/tmp/ai-screenshot-${name}-${Date.now()}.png`;
  await browser.screenshot(tmpPath);
  const file = Bun.file(tmpPath);
  const buf = await file.arrayBuffer();
  return Buffer.from(buf).toString('base64');
}
