#!/usr/bin/env bun

import { existsSync, mkdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { AgentBrowser, type CapturePersona } from './agent-browser.js';
import { TEST_ACCOUNTS, ORIGNABASE_URL, WEB_APP_URL } from './config.js';

const OUT_DIR = process.env.SCREENSHOT_OUT_DIR || '/tmp/origna-investor-deck-live';
const MIN_SCREENSHOTS = Number(process.env.MIN_INVESTOR_SCREENSHOTS || 320);

type Persona = CapturePersona | 'guest';

type Scenario = {
  id: string;
  persona: Persona;
  path: string;
  anchors: string[];
};

type DirectAuth = {
  accessToken: string;
  refreshToken: string;
};

const VIEWPORTS = [
  { name: 'mobile', width: 390, height: 844 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'wide', width: 1728, height: 1117 },
];

const SCROLL_POSITIONS = [0, 720, 1440, 2160, 2880];

const SCENARIOS: Scenario[] = [
  { id: 'guest-home', persona: 'guest', path: '/', anchors: ['Origna', 'Privacy Policy', 'Terms of Service', 'search'] },
  { id: 'guest-login', persona: 'guest', path: '/login', anchors: ['login', 'email', 'password', 'Origna'] },
  { id: 'guest-privacy', persona: 'guest', path: '/privacy-policy', anchors: ['privacy', 'confidentialite', 'Origna'] },
  { id: 'guest-terms', persona: 'guest', path: '/terms-of-service', anchors: ['terms', 'legal', 'Origna'] },
  { id: 'buyer-home', persona: 'buyer', path: '/', anchors: ['btn-home-settings', 'btn-cart', 'search', 'product'] },
  { id: 'buyer-profile', persona: 'buyer', path: '/profile', anchors: ['Settings', 'Parametres', 'Abonnement', 'profile'] },
  { id: 'buyer-orders', persona: 'buyer', path: '/orders', anchors: ['Orders', 'Commandes', 'order'] },
  { id: 'buyer-favorites', persona: 'buyer', path: '/favorites', anchors: ['Favorites', 'Favoris', 'favorite'] },
  { id: 'buyer-notifications', persona: 'buyer', path: '/notifications', anchors: ['Notifications', 'notification'] },
  { id: 'buyer-addresses', persona: 'buyer', path: '/addresses', anchors: ['Address', 'Adresse', 'Adresses'] },
  { id: 'buyer-subscription', persona: 'buyer', path: '/subscription', anchors: ['Premium', 'Subscription', 'Abonnement'] },
  { id: 'buyer-chat', persona: 'buyer', path: '/chat/inbox', anchors: ['Messages', 'chat', 'Premium', 'inbox'] },
  { id: 'buyer-cart', persona: 'buyer', path: '/cart', anchors: ['Cart', 'Panier', 'checkout'] },
  { id: 'buyer-checkout', persona: 'buyer', path: '/checkout', anchors: ['Checkout', 'payment', 'address', 'adresse'] },
  { id: 'buyer-support', persona: 'buyer', path: '/support', anchors: ['Support', 'message', 'contact'] },
  { id: 'buyer-security', persona: 'buyer', path: '/security-settings', anchors: ['Security', 'securite', 'password'] },
  { id: 'seller-products', persona: 'seller', path: '/seller/products', anchors: ['products', 'produits', 'Ajouter'] },
  { id: 'seller-orders', persona: 'seller', path: '/seller/orders', anchors: ['orders', 'commandes', 'seller'] },
  { id: 'seller-analytics', persona: 'seller', path: '/seller/analytics', anchors: ['Analytics', 'Analytique', 'Revenue'] },
  { id: 'seller-integration', persona: 'seller', path: '/seller/integration', anchors: ['Integration', 'Stripe', 'Connect'] },
  { id: 'seller-warehouses', persona: 'seller', path: '/seller/warehouses', anchors: ['Warehouse', 'entrepot', 'stock'] },
  { id: 'seller-bulk-upload', persona: 'seller', path: '/seller/bulk-upload', anchors: ['bulk', 'CSV', 'upload'] },
  { id: 'seller-add-product', persona: 'seller', path: '/add-product', anchors: ['product', 'produit', 'Nom'] },
  { id: 'admin-panel', persona: 'admin', path: '/admin', anchors: ['admin', 'Users', 'Utilisateurs', 'Panneau'] },
  { id: 'admin-users', persona: 'admin', path: '/admin', anchors: ['admin', 'Users', 'Utilisateurs'] },
  { id: 'admin-products', persona: 'admin', path: '/admin', anchors: ['admin', 'Products', 'Produits'] },
  { id: 'admin-orders', persona: 'admin', path: '/admin', anchors: ['admin', 'Orders', 'Commandes'] },
];

function credentialsForPersona(persona: CapturePersona): { email: string; password: string } {
  switch (persona) {
    case 'buyer':
      return { email: TEST_ACCOUNTS.BUYER_EMAIL, password: TEST_ACCOUNTS.BUYER_PASS };
    case 'seller':
      return { email: TEST_ACCOUNTS.SELLER_EMAIL, password: TEST_ACCOUNTS.SELLER_PASS };
    case 'admin':
      return { email: TEST_ACCOUNTS.ADMIN_EMAIL, password: TEST_ACCOUNTS.ADMIN_PASS };
  }
}

async function directLogin(email: string, password: string): Promise<DirectAuth> {
  const response = await fetch(`${ORIGNABASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || !body?.access_token) {
    throw new Error(
      `Deck capture login failed for ${email}: ${body?.error?.message ?? body?.message ?? response.status}`,
    );
  }
  return {
    accessToken: String(body.access_token),
    refreshToken: String(body.refresh_token ?? ''),
  };
}

async function login(browser: AgentBrowser, persona: Persona): Promise<void> {
  if (persona === 'guest') {
    await browser.clearState();
    return;
  }

  const creds = credentialsForPersona(persona);
  const auth = await directLogin(creds.email, creds.password);
  await browser.installAuthSession(
    creds.email,
    auth.accessToken,
    auth.refreshToken,
  );
}

function hasUsefulContent(raw: string, anchors: string[]): boolean {
  const lower = raw.toLowerCase();
  if (lower.includes('enable accessibility') && !lower.includes('origna')) return false;
  if (lower.includes('un probleme recurrent') || lower.includes('un problème récurrent')) return false;
  return anchors.some((anchor) => lower.includes(anchor.toLowerCase()));
}

async function setViewportAndScroll(
  browser: AgentBrowser,
  viewport: { width: number; height: number },
  y: number,
): Promise<void> {
  browser.run(['set', 'viewport', String(viewport.width), String(viewport.height)], 10_000);
  await new Promise((resolve) => setTimeout(resolve, 500));
  browser.run(['eval', `window.scrollTo(0, ${y}); JSON.stringify({x: window.scrollX, y: window.scrollY})`], 10_000);
  await new Promise((resolve) => setTimeout(resolve, 900));
}

function screenshotLooksWritten(path: string): boolean {
  if (!existsSync(path)) return false;
  return statSync(path).size > 20_000;
}

async function captureCurrentView(
  browser: AgentBrowser,
  scenario: Scenario,
  viewport: { name: string; width: number; height: number },
  scrollY: number,
  count: number,
): Promise<boolean> {
  await setViewportAndScroll(browser, viewport, scrollY);
  const snap = await browser.snapshot({ compact: true });
  if (!hasUsefulContent(snap.raw, scenario.anchors)) {
    console.warn(`[investor-capture] skip ${scenario.id} ${viewport.name} y=${scrollY}: anchors missing`);
    return false;
  }

  const filename = `${String(count + 1).padStart(3, '0')}-${scenario.id}-${viewport.name}-y${scrollY}.png`;
  const filepath = join(OUT_DIR, filename);
  await browser.screenshot(filepath);
  if (!screenshotLooksWritten(filepath)) {
    console.warn(`[investor-capture] skip ${filename}: screenshot missing or too small`);
    return false;
  }

  console.log(`[investor-capture] ${filename}`);
  return true;
}

async function main(): Promise<void> {
  mkdirSync(OUT_DIR, { recursive: true });
  const browser = new AgentBrowser();
  let currentPersona: Persona | null = null;
  let captured = 0;

  try {
    for (const scenario of SCENARIOS) {
      if (captured >= MIN_SCREENSHOTS) break;

      try {
        if (currentPersona !== scenario.persona) {
          await login(browser, scenario.persona);
          currentPersona = scenario.persona;
        }

        await browser.open(`${WEB_APP_URL}${scenario.path}`, 60_000);
        await browser.waitForFlutter().catch(() => undefined);
        await browser.enableAccessibilityIfPresent();
        await new Promise((resolve) => setTimeout(resolve, 1800));

        for (const viewport of VIEWPORTS) {
          for (const scrollY of SCROLL_POSITIONS) {
            if (captured >= MIN_SCREENSHOTS) break;
            try {
              if (await captureCurrentView(browser, scenario, viewport, scrollY, captured)) {
                captured += 1;
              }
            } catch (error) {
              console.warn(`[investor-capture] failed ${scenario.id}: ${String(error).slice(0, 160)}`);
            }
          }
        }
      } catch (error) {
        console.warn(`[investor-capture] scenario failed ${scenario.id}: ${String(error).slice(0, 220)}`);
      }
    }
  } finally {
    await browser.close().catch(() => undefined);
  }

  if (captured < 300) {
    throw new Error(`Investor deck capture produced only ${captured} screenshots; expected at least 300.`);
  }

  console.log(`[investor-capture] complete: ${captured} screenshots in ${OUT_DIR}`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
