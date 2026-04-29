#!/usr/bin/env bun

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, rmSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { chromium, type Page } from 'playwright';
import {
  ORIGNABASE_URL,
  TEST_ACCOUNTS,
  VENTURES_WEB_URL,
  WEB_APP_URL,
} from './config.js';

const OUT_DIR =
  process.env.SCREENSHOT_OUT_DIR || '../origna_ventures/output/desktop-screenshots';
const MIN_SCREENSHOTS = Number(process.env.MIN_INVESTOR_SCREENSHOTS || 64);

type Persona = 'guest' | 'buyer' | 'seller' | 'admin';

type AuthSession = {
  email: string;
  accessToken: string;
  refreshToken: string;
};

type CaptureTarget = {
  id: string;
  app: 'gta' | 'ventures';
  persona: Persona;
  path: string;
  actions?: Array<'focus-search' | 'contact-form'>;
};

const DESKTOP_VIEWPORTS = [
  { name: 'desktop-1280', width: 1280, height: 900 },
  { name: 'desktop-1440', width: 1440, height: 900 },
  { name: 'desktop-1600', width: 1600, height: 900 },
  { name: 'desktop-1728', width: 1728, height: 900 },
];

const GTA_TARGETS: CaptureTarget[] = [
  { id: 'gta-guest-home', app: 'gta', persona: 'guest', path: '/', actions: ['focus-search'] },
  { id: 'gta-guest-login', app: 'gta', persona: 'guest', path: '/login' },
  { id: 'gta-guest-privacy', app: 'gta', persona: 'guest', path: '/privacy-policy' },
  { id: 'gta-guest-terms', app: 'gta', persona: 'guest', path: '/terms-of-service' },
  { id: 'gta-buyer-home', app: 'gta', persona: 'buyer', path: '/', actions: ['focus-search'] },
  { id: 'gta-buyer-profile', app: 'gta', persona: 'buyer', path: '/profile' },
  { id: 'gta-buyer-orders', app: 'gta', persona: 'buyer', path: '/orders' },
  { id: 'gta-buyer-favorites', app: 'gta', persona: 'buyer', path: '/favorites' },
  { id: 'gta-buyer-notifications', app: 'gta', persona: 'buyer', path: '/notifications' },
  { id: 'gta-buyer-addresses', app: 'gta', persona: 'buyer', path: '/addresses' },
  { id: 'gta-buyer-subscription', app: 'gta', persona: 'buyer', path: '/subscription' },
  { id: 'gta-buyer-chat', app: 'gta', persona: 'buyer', path: '/chat/inbox' },
  { id: 'gta-buyer-cart', app: 'gta', persona: 'buyer', path: '/cart' },
  { id: 'gta-buyer-browse-products', app: 'gta', persona: 'buyer', path: '/', actions: ['focus-search'] },
  { id: 'gta-buyer-support', app: 'gta', persona: 'buyer', path: '/support' },
  { id: 'gta-buyer-security', app: 'gta', persona: 'buyer', path: '/security-settings' },
  { id: 'gta-seller-products', app: 'gta', persona: 'seller', path: '/seller/products' },
  { id: 'gta-seller-orders', app: 'gta', persona: 'seller', path: '/seller/orders' },
  { id: 'gta-seller-analytics', app: 'gta', persona: 'seller', path: '/seller/analytics' },
  { id: 'gta-seller-integration', app: 'gta', persona: 'seller', path: '/seller/integration' },
  { id: 'gta-seller-warehouses', app: 'gta', persona: 'seller', path: '/seller/warehouses' },
  { id: 'gta-seller-bulk-upload', app: 'gta', persona: 'seller', path: '/seller/bulk-upload' },
  { id: 'gta-seller-add-product', app: 'gta', persona: 'seller', path: '/add-product' },
  { id: 'gta-admin-panel', app: 'gta', persona: 'admin', path: '/admin' },
  { id: 'gta-admin-users', app: 'gta', persona: 'admin', path: '/admin' },
  { id: 'gta-admin-products', app: 'gta', persona: 'admin', path: '/admin' },
  { id: 'gta-admin-orders', app: 'gta', persona: 'admin', path: '/admin' },
];

const VENTURES_TARGETS: CaptureTarget[] = [
  { id: 'ventures-site-sections-a', app: 'ventures', persona: 'guest', path: '/' },
  { id: 'ventures-site-sections-b', app: 'ventures', persona: 'guest', path: '/' },
  { id: 'ventures-site-sections-c', app: 'ventures', persona: 'guest', path: '/' },
  { id: 'ventures-contact-form', app: 'ventures', persona: 'guest', path: '/', actions: ['contact-form'] },
];

function credentialsForPersona(persona: Exclude<Persona, 'guest'>): {
  email: string;
  password: string;
} {
  switch (persona) {
    case 'buyer':
      return { email: TEST_ACCOUNTS.BUYER_EMAIL, password: TEST_ACCOUNTS.BUYER_PASS };
    case 'seller':
      return { email: TEST_ACCOUNTS.SELLER_EMAIL, password: TEST_ACCOUNTS.SELLER_PASS };
    case 'admin':
      return { email: TEST_ACCOUNTS.ADMIN_EMAIL, password: TEST_ACCOUNTS.ADMIN_PASS };
  }
}

async function loginPersona(persona: Exclude<Persona, 'guest'>): Promise<AuthSession> {
  const creds = credentialsForPersona(persona);
  const response = await fetch(`${ORIGNABASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: creds.email, password: creds.password }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || !body?.access_token) {
    throw new Error(
      `Deck capture ${persona} login failed for ${creds.email}: ${
        body?.error?.message ?? body?.message ?? response.status
      }`,
    );
  }
  return {
    email: creds.email,
    accessToken: String(body.access_token),
    refreshToken: String(body.refresh_token ?? ''),
  };
}

function baseUrlFor(target: CaptureTarget): string {
  return target.app === 'gta' ? WEB_APP_URL : VENTURES_WEB_URL;
}

function screenshotLooksWritten(path: string, minBytes = 25_000): boolean {
  return existsSync(path) && statSync(path).size > minBytes;
}

function scrollPositions(maxScroll: number): number[] {
  if (maxScroll <= 0) return [0];
  return [0, 0.25, 0.5, 0.75].map((ratio) => Math.round(maxScroll * ratio));
}

async function installAuth(page: Page, session: AuthSession | null): Promise<void> {
  await page.evaluate((auth) => {
    localStorage.clear();
    sessionStorage.clear();
    if (!auth) return;
    localStorage.setItem('orignabase_access_token', auth.accessToken);
    localStorage.setItem('orignabase_refresh_token', auth.refreshToken);
    localStorage.setItem('orignabase_email', auth.email);
  }, session);
}

async function waitForLiveApp(page: Page, target: CaptureTarget): Promise<void> {
  await page.waitForLoadState('domcontentloaded', { timeout: 45_000 });
  await page.waitForLoadState('networkidle', { timeout: 20_000 }).catch(() => undefined);
  if (target.app === 'gta') {
    await page
      .waitForFunction(
        () => document.body.innerText.toLowerCase().includes('origna') || document.querySelector('flt-glass-pane'),
        undefined,
        { timeout: 25_000 },
      )
      .catch((error) => {
        throw new Error(`GTA app did not become ready for ${target.id}: ${error}`);
      });
    if (target.path !== '/' && !page.url().includes(target.path)) {
      throw new Error(`Expected ${target.id} URL to include ${target.path}, got ${page.url()}`);
    }
  } else {
    await page.waitForSelector('body', { timeout: 20_000 });
    const bodyText = (await page.locator('body').innerText({ timeout: 10_000 })).toLowerCase();
    if (!bodyText.includes('origna ventures')) {
      throw new Error(`Ventures app did not load expected content for ${target.id}`);
    }
  }
  await page.waitForTimeout(1_000);
}

async function applyActions(page: Page, target: CaptureTarget): Promise<void> {
  for (const action of target.actions ?? []) {
    if (action === 'focus-search') {
      const search = page
        .getByRole('textbox')
        .filter({ hasText: /search|recherche|buscar/i })
        .first();
      await search.click({ timeout: 1_000 }).catch(() => undefined);
      await page.keyboard.type('Origna', { delay: 15 }).catch(() => undefined);
    }
    if (action === 'contact-form') {
      await page.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight));
      await page.waitForTimeout(400);
      const fields = page.locator('input:not([disabled]), textarea:not([disabled])');
      const count = await fields.count();
      if (count < 3) {
        console.warn(
          `[investor-desktop-capture] skip contact fill on ${target.id}: expected enabled contact fields, found ${count}`,
        );
        continue;
      }
      const values = ['Investor QA', 'investor@example.com', 'Launch review', 'Checking live deck captures.'];
      for (let i = 0; i < Math.min(count, values.length); i += 1) {
        await fields.nth(i).fill(values[i], { timeout: 2_000 });
      }
    }
  }
  if (target.id === 'gta-admin-products') {
    await page.getByText(/products|produits/i).click({ timeout: 2_000 }).catch(() => undefined);
  }
  if (target.id === 'gta-admin-orders') {
    await page.getByText(/orders|commandes/i).click({ timeout: 2_000 }).catch(() => undefined);
  }
}

async function main(): Promise<void> {
  rmSync(OUT_DIR, { recursive: true, force: true });
  mkdirSync(OUT_DIR, { recursive: true });

  const sessions = new Map<Persona, AuthSession | null>([['guest', null]]);
  sessions.set('buyer', await loginPersona('buyer'));
  sessions.set('seller', await loginPersona('seller'));
  sessions.set('admin', await loginPersona('admin'));

  const browser = await chromium.launch({ headless: true });
  let captured = 0;
  const targets = [...GTA_TARGETS, ...VENTURES_TARGETS];
  const seenImageHashes = new Set<string>();

  try {
    const context = await browser.newContext({ deviceScaleFactor: 1 });
    const page = await context.newPage();

    outer: for (const viewport of DESKTOP_VIEWPORTS) {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });

      for (const target of targets) {
        if (captured >= MIN_SCREENSHOTS) break outer;

        const base = baseUrlFor(target).replace(/\/$/, '');
        await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 45_000 });
        await installAuth(page, sessions.get(target.persona) ?? null);
        await page.goto(`${base}${target.path}`, { waitUntil: 'domcontentloaded', timeout: 45_000 });
        await waitForLiveApp(page, target);
        await applyActions(page, target);

        const maxScroll = await page.evaluate(() =>
          Math.max(
            0,
            document.documentElement.scrollHeight,
            document.body.scrollHeight,
          ) - window.innerHeight,
        );

        for (const [index, scrollY] of scrollPositions(maxScroll).entries()) {
          if (captured >= MIN_SCREENSHOTS) break outer;

          if (index === 0) {
            await page.keyboard.press('Home').catch(() => undefined);
            await page.evaluate(() => window.scrollTo(0, 0)).catch(() => undefined);
          } else if (maxScroll > 0) {
            await page.evaluate((y) => window.scrollTo(0, y), scrollY);
          } else {
            await page.mouse.wheel(0, 720);
          }
          await page.waitForTimeout(350);
          await page.mouse.move(
            Math.round(viewport.width * (0.22 + (index % 4) * 0.16)),
            Math.round(viewport.height * (0.28 + (index % 3) * 0.18)),
          );

          const filename = `${String(captured + 1).padStart(3, '0')}-live-${target.id}-${viewport.name}-y${String(
            scrollY,
          ).padStart(5, '0')}.png`;
          const filepath = join(OUT_DIR, filename);
          const image = await page.screenshot({ fullPage: false });
          const imageHash = createHash('sha256').update(image).digest('hex');
          if (seenImageHashes.has(imageHash)) {
            console.log(
              `[investor-desktop-capture] skip duplicate ${target.id} ${viewport.name} y=${scrollY}`,
            );
            continue;
          }
          seenImageHashes.add(imageHash);
          await Bun.write(filepath, image);
          if (!screenshotLooksWritten(filepath)) {
            throw new Error(`Screenshot missing or too small: ${filepath}`);
          }
          captured += 1;
          console.log(`[investor-desktop-capture] ${filename}`);
        }
      }
    }
  } finally {
    await browser.close();
  }

  if (captured < MIN_SCREENSHOTS) {
    throw new Error(`Captured ${captured}; expected at least ${MIN_SCREENSHOTS}.`);
  }

  console.log(`[investor-desktop-capture] complete: ${captured} screenshots in ${OUT_DIR}`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
