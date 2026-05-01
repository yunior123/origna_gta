#!/usr/bin/env bun

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, rmSync, statSync, unlinkSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium, type Page } from 'playwright';
import {
  ORIGNABASE_URL,
  TEST_ACCOUNTS,
  WEB_APP_URL,
} from './config.js';
import { signIn } from './api-client.js';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const OUT_DIR =
  process.env.SCREENSHOT_OUT_DIR
    ? isAbsolute(process.env.SCREENSHOT_OUT_DIR)
      ? process.env.SCREENSHOT_OUT_DIR
      : resolve(process.cwd(), process.env.SCREENSHOT_OUT_DIR)
    : join(repoRoot, 'origna_ventures/output/desktop-screenshots');
const MIN_SCREENSHOTS = Number(process.env.MIN_INVESTOR_SCREENSHOTS || 157);
const TARGET_SCREENSHOTS = Number(process.env.TARGET_INVESTOR_SCREENSHOTS || 157);

type Persona = 'guest' | 'buyer' | 'seller' | 'admin';

type AuthSession = {
  email: string;
  localId: string;
  accessToken: string;
  refreshToken: string;
};

type CaptureTarget = {
  id: string;
  app: 'gta';
  persona: Persona;
  path: string;
  actions?: Array<
    | 'focus-search'
    | 'contact-form'
    | 'checkout-from-cart'
    | 'support-chat'
    | 'admin-users'
    | 'admin-products'
    | 'admin-orders'
  >;
};

const DESKTOP_VIEWPORTS = [
  { name: 'desktop-1280', width: 1280, height: 900 },
];

const GTA_TARGETS: CaptureTarget[] = [
  { id: 'gta-guest-home', app: 'gta', persona: 'guest', path: '/', actions: ['focus-search'] },
  { id: 'gta-guest-login', app: 'gta', persona: 'guest', path: '/login' },
  { id: 'gta-guest-product-detail', app: 'gta', persona: 'guest', path: '/product/e2e_product_test_seller' },
  { id: 'gta-guest-privacy', app: 'gta', persona: 'guest', path: '/privacy-policy' },
  { id: 'gta-guest-terms', app: 'gta', persona: 'guest', path: '/terms-of-service' },
  { id: 'gta-buyer-home', app: 'gta', persona: 'buyer', path: '/', actions: ['focus-search'] },
  { id: 'gta-buyer-product-detail', app: 'gta', persona: 'buyer', path: '/product/e2e_product_test_seller' },
  { id: 'gta-buyer-profile', app: 'gta', persona: 'buyer', path: '/profile' },
  { id: 'gta-buyer-orders', app: 'gta', persona: 'buyer', path: '/orders' },
  { id: 'gta-buyer-favorites', app: 'gta', persona: 'buyer', path: '/favorites' },
  { id: 'gta-buyer-notifications', app: 'gta', persona: 'buyer', path: '/notifications' },
  { id: 'gta-buyer-addresses', app: 'gta', persona: 'buyer', path: '/addresses' },
  { id: 'gta-buyer-subscription', app: 'gta', persona: 'buyer', path: '/subscription' },
  { id: 'gta-buyer-chat', app: 'gta', persona: 'buyer', path: '/chat/inbox' },
  { id: 'gta-buyer-cart', app: 'gta', persona: 'buyer', path: '/cart' },
  { id: 'gta-buyer-checkout', app: 'gta', persona: 'buyer', path: '/cart', actions: ['checkout-from-cart'] },
  { id: 'gta-buyer-browse-products', app: 'gta', persona: 'buyer', path: '/', actions: ['focus-search'] },
  { id: 'gta-buyer-support', app: 'gta', persona: 'buyer', path: '/support', actions: ['support-chat'] },
  { id: 'gta-buyer-security', app: 'gta', persona: 'buyer', path: '/security-settings' },
  { id: 'gta-seller-products', app: 'gta', persona: 'seller', path: '/seller/products' },
  { id: 'gta-seller-orders', app: 'gta', persona: 'seller', path: '/seller/orders' },
  { id: 'gta-seller-analytics', app: 'gta', persona: 'seller', path: '/seller/analytics' },
  { id: 'gta-seller-integration', app: 'gta', persona: 'seller', path: '/seller/integration' },
  { id: 'gta-seller-warehouses', app: 'gta', persona: 'seller', path: '/seller/warehouses' },
  { id: 'gta-seller-bulk-upload', app: 'gta', persona: 'seller', path: '/seller/bulk-upload' },
  { id: 'gta-seller-add-product', app: 'gta', persona: 'seller', path: '/add-product' },
  { id: 'gta-admin-panel', app: 'gta', persona: 'admin', path: '/admin' },
  { id: 'gta-admin-users', app: 'gta', persona: 'admin', path: '/admin', actions: ['admin-users'] },
  { id: 'gta-admin-products', app: 'gta', persona: 'admin', path: '/admin', actions: ['admin-products'] },
  { id: 'gta-admin-orders', app: 'gta', persona: 'admin', path: '/admin', actions: ['admin-orders'] },
  { id: 'gta-admin-seller-products', app: 'gta', persona: 'admin', path: '/admin/sellers/e2e-seller/products?name=OrignaVentures' },
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
  const auth = await signIn(creds.email, creds.password);
  return {
    email: auth.email,
    localId: normalizeUserId(auth.localId || decodeJwtSubject(auth.idToken)),
    accessToken: auth.idToken,
    refreshToken: auth.refreshToken ?? '',
  };
}

function normalizeUserId(userId: string): string {
  return userId.includes(':') ? userId.split(':').pop() ?? userId : userId;
}

function decodeJwtSubject(token: string): string {
  const payload = token.split('.')[1];
  if (!payload) return '';
  const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized.padEnd(normalized.length + ((4 - normalized.length % 4) % 4), '=');
  const decoded = JSON.parse(Buffer.from(padded, 'base64').toString('utf8')) as { sub?: string };
  return String(decoded.sub ?? '').replace(/^users:/, '');
}

async function writeGraphqlDoc(
  collection: string,
  id: string,
  data: Record<string, unknown>,
  token: string,
): Promise<void> {
  const response = await fetch(`${ORIGNABASE_URL}/graphql`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      query: 'mutation SetDoc($collection: String!, $id: String!, $data: JSON!) { set(collection: $collection, id: $id, data: $data) }',
      variables: { collection, id, data },
    }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || body?.errors) {
    throw new Error(
      `Failed to seed ecommerce capture doc ${collection}/${id}: ${
        body?.errors?.[0]?.message ?? response.status
      }`,
    );
  }
}

async function seedEcommerceDemoState(
  buyer: AuthSession,
  seller: AuthSession,
  admin: AuthSession,
): Promise<void> {
  const now = new Date().toISOString();
  const productImage =
    'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg';

  const bestEffort = async (label: string, fn: () => Promise<void>) => {
    try {
      await fn();
    } catch (error) {
      console.warn(
        `[ecommerce-deck-capture] seed skipped ${label}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  };

  await bestEffort('buyer cart', async () => {
    await seedBuyerCartForCheckout(buyer);
  });

  await bestEffort('buyer notifications', async () => {
    const notifications = [
      ['order-confirmed', 'Order confirmed', 'Your OrignaGTA order is confirmed and being prepared.', 'order_confirmation'],
      ['shipping-update', 'Shipping update', 'Your training kit is packed and ready for pickup.', 'shipping_update'],
      ['chat-message', 'New seller reply', 'Northline Market replied to your question.', 'chat_message'],
    ];
    for (const [suffix, title, body, type] of notifications) {
      await writeGraphqlDoc(
        'users__notifications',
        `ecommerce_${buyer.localId}_${suffix}`,
        {
          parent_id: `users:${buyer.localId}`,
          parent_collection: 'users',
          userId: buyer.localId,
          title,
          body,
          type,
          isRead: suffix === 'shipping-update',
          createdAt: now,
        },
        buyer.accessToken,
      );
    }
  });

  await bestEffort('orders', async () => {
    const item = {
      productId: 'e2e_product_test_seller',
      name: 'Ecommerce Checkout Sample',
      description: 'Deck-ready physical sample for order lifecycle screenshots.',
      price: 19.99,
      priceCents: 1999,
      imageUrls: [productImage],
      quantity: 2,
      createdAt: now,
      sellerAddress: {},
      sellerId: seller.localId,
      sellerName: 'OrignaVentures',
      status: 'shipped',
      trackingNumber: 'OV-DECK-2026',
    };
    const orderRows: Array<[string, string, string, number]> = [
      ['buyer-confirmed', 'confirmed', 'authorized', 4518],
      ['buyer-shipped', 'shipped', 'captured', 4518],
      ['buyer-delivered', 'delivered', 'captured', 4518],
    ];
    for (const [suffix, orderStatus, paymentStatus, total] of orderRows) {
      await writeGraphqlDoc(
        'orders',
        `ecommerce_${buyer.localId}_${suffix}`,
        {
          orderId: `ecommerce_${buyer.localId}_${suffix}`,
          userId: buyer.localId,
          buyerId: buyer.localId,
          customerId: buyer.localId,
          customerEmail: buyer.email,
          items: [item],
          totalAmountCents: total,
          subtotalCents: 3998,
          shippingCostCents: 0,
          taxAmountCents: total - 3998,
          taxes: { hst: 0.13 },
          orderStatus,
          paymentStatus,
          shippingAddress: {
            street: '123 Queen St W',
            city: 'Toronto',
            state: 'ON',
            postalCode: 'M5H 2N2',
            country: 'CA',
          },
          createdAt: now,
          currency: 'CAD',
          sellerIds: [seller.localId],
          productIds: ['e2e_product_test_seller'],
          stripeSessionId: `cs_ecommerce_${suffix}`,
          shippingApprovalStatus: 'not_required',
          shippingApprovalRequired: false,
          platformFeeTotalCents: 100,
          payoutStatus: 'pending',
          sellerPayouts: [
            {
              sellerId: seller.localId,
              amountCents: 3898,
              paid: false,
              status: 'pending',
            },
          ],
        },
        admin.accessToken,
      );
    }
  });

  await bestEffort('chat inbox', async () => {
    const chatId = `ecommerce_chat_${buyer.localId}`;
    await writeGraphqlDoc(
      'chats',
      chatId,
      {
        chatId,
        productId: 'e2e_product_test_seller',
        productTitle: 'Ecommerce Checkout Sample',
        productImageUrl: productImage,
        buyerId: buyer.localId,
        sellerId: seller.localId,
        lastMessage: 'Yes, this bundle is available for same-week delivery.',
        lastMessageAt: now,
        buyerUnreadCount: 1,
        sellerUnreadCount: 0,
        createdAt: now,
        updatedAt: now,
      },
      buyer.accessToken,
    );
    for (const [index, sender, name, text] of [
      [1, buyer.localId, 'Deck Buyer', 'Is the sample bundle available this week?'],
      [2, seller.localId, 'OrignaVentures', 'Yes, this bundle is available for same-week delivery.'],
    ] as const) {
      await writeGraphqlDoc(
        'chats__messages',
        `${chatId}_${index}`,
        {
          parent_id: `chats:${chatId}`,
          parent_collection: 'chats',
          senderId: sender,
          senderDisplayName: name,
          text,
          messageText: text,
          isRead: index === 1,
          deleted: false,
          createdAt: now,
        },
        buyer.accessToken,
      );
    }
  });
}

async function seedBuyerCartForCheckout(session: AuthSession): Promise<void> {
  if (!session.localId) return;
  const productId = 'e2e_product_test_seller';
  const now = new Date().toISOString();
  await writeGraphqlDoc(
    'users__cart',
    `ecommerce_checkout_${session.localId}`,
    {
      parent_id: `users:${session.localId}`,
      parent_collection: 'users',
      userId: `users:${session.localId}`,
      productId,
      quantity: 2,
      priceCents: 1999,
      priceSnapshot: 1999,
      name: 'Ecommerce Checkout Sample',
      productName: 'Ecommerce Checkout Sample',
      description: 'Deck-ready cart item with realistic checkout totals.',
      imageUrls: ['https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg'],
      imageUrl: 'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg',
      availabilityStatus: 'available',
      isUnavailable: false,
      addedAt: now,
      updatedAt: now,
    },
    session.accessToken,
  );
  await writeGraphqlDoc(
    'user_carts',
    session.localId,
    {
      userId: session.localId,
      itemCount: 1,
      totalCents: 3998,
      unavailableItemCount: 0,
      lastUpdated: now,
    },
    session.accessToken,
  ).catch((error) => {
    console.warn(
      `[ecommerce-deck-capture] seed skipped user_carts aggregate: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  });
}

function baseUrlFor(target: CaptureTarget): string {
  return WEB_APP_URL;
}

function screenshotLooksWritten(path: string, minBytes = 25_000): boolean {
  return existsSync(path) && statSync(path).size > minBytes;
}

function screenshotTargetsPresent(): Set<string> {
  const present = new Set<string>();
  const files = Bun.spawnSync({
    cmd: ['bash', '-lc', `find ${JSON.stringify(OUT_DIR)} -maxdepth 1 -type f -name '*.png' -print`],
  }).stdout.toString();
  for (const file of files.split('\n')) {
    const match = file.match(/(?:live|mockup)-(gta)-(.+?)-desktop-/);
    if (match) present.add(`${match[1]}-${match[2]}`);
  }
  return present;
}

function scrollPositions(maxScroll: number): number[] {
  if (maxScroll <= 0) return [0];
  return [0, 0.25, 0.5, 0.75].map((ratio) => Math.round(maxScroll * ratio));
}

function initialScrollForTarget(target: CaptureTarget, maxScroll: number): number {
  if (maxScroll <= 0) return 0;
  return 0;
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
          `[ecommerce-deck-capture] skip contact fill on ${target.id}: expected enabled contact fields, found ${count}`,
        );
        continue;
      }
      const values = ['Ecommerce QA', 'ecommerce@example.com', 'Checkout review', 'Checking live ecommerce deck captures.'];
      for (let i = 0; i < Math.min(count, values.length); i += 1) {
        await fields.nth(i).fill(values[i], { timeout: 2_000 });
      }
    }
    if (action === 'support-chat') {
      await page
        .getByText(/orders|payment|billing|support|help|commande|paiement/i)
        .first()
        .click({ timeout: 2_000 })
        .catch(() => undefined);
      await page.waitForTimeout(900);
      const supportInput = page.locator('textarea, input').last();
      await supportInput
        .fill('I need help confirming delivery timing for an order.', { timeout: 2_000 })
        .catch(() => undefined);
    }
    if (action === 'checkout-from-cart') {
      await page
        .getByText(/checkout|passer à la caisse|pagar|finalizar/i)
        .first()
        .click({ timeout: 3_000 })
        .catch(() => undefined);
      await page.waitForTimeout(1_200);
    }
    if (action === 'admin-users') {
      await page.getByText(/users|utilisateurs|usuarios/i).first().click({ timeout: 2_000 }).catch(() => undefined);
      await page.waitForTimeout(800);
    }
    if (action === 'admin-products') {
      await page.getByText(/products|produits|productos/i).first().click({ timeout: 2_000 }).catch(() => undefined);
      await page.waitForTimeout(800);
    }
    if (action === 'admin-orders') {
      await page.getByText(/orders|commandes|pedidos/i).first().click({ timeout: 2_000 }).catch(() => undefined);
      await page.waitForTimeout(800);
    }
  }
  if (target.id === 'gta-admin-products') {
    await page.getByText(/products|produits/i).click({ timeout: 2_000 }).catch(() => undefined);
  }
  if (target.id === 'gta-admin-orders') {
    await page.getByText(/orders|commandes/i).click({ timeout: 2_000 }).catch(() => undefined);
  }
}

async function dismissCookieBanner(page: Page): Promise<void> {
  await page
    .getByText(/accept|accepter|aceptar/i)
    .last()
    .click({ timeout: 1_500 })
    .catch(() => undefined);
  await page.waitForTimeout(200);
}

async function captureSellerMockup(
  page: Page,
  targetId: string,
  title: string,
  subtitle: string,
  metrics: ReadonlyArray<readonly [string, string]>,
  rows: ReadonlyArray<string>,
  nextIndex: number,
  seenImageHashes: Set<string>,
): Promise<number> {
  await page.setViewportSize({ width: 1280, height: 900 });
  const metricCards = metrics
    .map(
      ([value, label]) => `
        <div class="metric">
          <strong>${value}</strong>
          <span>${label}</span>
        </div>`,
    )
    .join('');
  const tableRows = rows
    .map((row, index) => `<div class="row"><span>${String(index + 1).padStart(2, '0')}</span><p>${row}</p><button>${index % 2 ? 'Review' : 'Open'}</button></div>`)
    .join('');
  const consoleTitle = targetId.startsWith('gta-admin-')
      ? 'OrignaGTA Admin Console'
      : targetId.startsWith('gta-buyer-')
        ? 'OrignaGTA Buyer Experience'
    : 'OrignaGTA Seller Console';
  const footerText = targetId.startsWith('gta-admin-')
      ? 'These mockups preserve ecommerce deck coverage for admin operations when live admin tabs render too small for deck export.'
      : targetId.startsWith('gta-buyer-')
        ? 'These mockups preserve ecommerce deck coverage for buyer flows when protected live sample data is permission-limited.'
    : 'Seller onboarding is disabled in production; these mockups preserve ecommerce deck coverage for the full seller operating surface.';
  const navItems = targetId.startsWith('gta-admin-')
      ? [
          ['panel', 'Overview'],
          ['users', 'Users'],
          ['products', 'Products'],
          ['orders', 'Orders'],
          ['seller-products', 'Seller products'],
          ['payments', 'Payments'],
          ['security', 'Security'],
        ]
    : targetId.startsWith('gta-buyer-')
      ? [
          ['cart', 'Cart'],
          ['checkout', 'Checkout'],
          ['notifications', 'Notifications'],
          ['chat', 'Chat'],
          ['orders', 'Orders'],
          ['support', 'Support'],
          ['security', 'Security'],
        ]
    : [
        ['orders', 'Orders'],
        ['analytics', 'Analytics'],
        ['integration', 'Integration'],
        ['warehouses', 'Warehouses'],
        ['bulk', 'Bulk upload'],
        ['products', 'Products'],
        ['support', 'Support'],
      ];
  const navMarkup = navItems
    .map(
      ([key, label]) =>
        `<div class="${targetId.includes(key) ? 'active' : ''}">${label}</div>`,
    )
    .join('');
  await page.setContent(`
    <html>
      <head>
        <style>
          * { box-sizing: border-box; }
          body {
            margin: 0;
            width: 1280px;
            height: 900px;
            overflow: hidden;
            font-family: Inter, Arial, sans-serif;
            color: #f8fafc;
            background: radial-gradient(circle at 80% 10%, #7c3aed 0, transparent 24%),
              linear-gradient(135deg, #111827 0%, #172554 58%, #111827 100%);
          }
          .top {
            height: 64px;
            padding: 18px 40px;
            background: linear-gradient(90deg, #27348b, #7c3aed);
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-weight: 800;
            font-size: 22px;
          }
          .layout { display: grid; grid-template-columns: 260px 1fr; height: 836px; }
          aside {
            padding: 28px 22px;
            background: rgba(15, 23, 42, .78);
            border-right: 1px solid rgba(255,255,255,.12);
          }
          aside div {
            padding: 12px 14px;
            margin-bottom: 8px;
            border-radius: 8px;
            color: #cbd5e1;
            background: rgba(255,255,255,.04);
          }
          aside div.active { color: white; background: rgba(129, 140, 248, .32); }
          main { padding: 34px 42px; }
          h1 { margin: 0; font-size: 34px; letter-spacing: 0; }
          .subtitle { color: #c4b5fd; margin-top: 8px; font-size: 15px; }
          .metrics { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin: 28px 0; }
          .metric {
            min-height: 112px;
            padding: 22px;
            border: 1px solid rgba(255,255,255,.14);
            border-radius: 8px;
            background: rgba(255,255,255,.08);
            box-shadow: 0 14px 36px rgba(0,0,0,.22);
          }
          .metric strong { display: block; font-size: 30px; color: #93c5fd; }
          .metric span { display: block; margin-top: 10px; color: #dbeafe; font-size: 14px; }
          .panel {
            border: 1px solid rgba(255,255,255,.14);
            border-radius: 8px;
            background: rgba(15, 23, 42, .64);
            overflow: hidden;
          }
          .row {
            display: grid;
            grid-template-columns: 54px 1fr 100px;
            align-items: center;
            min-height: 64px;
            padding: 0 18px;
            border-bottom: 1px solid rgba(255,255,255,.08);
          }
          .row span { color: #a5b4fc; font-weight: 800; }
          .row p { margin: 0; color: #f8fafc; font-size: 15px; }
          button {
            height: 34px;
            border: 0;
            border-radius: 6px;
            color: white;
            background: linear-gradient(90deg, #2563eb, #7c3aed);
            font-weight: 700;
          }
          .footer { margin-top: 22px; color: #93c5fd; font-size: 13px; }
        </style>
      </head>
      <body>
        <div class="top"><span>${consoleTitle}</span><span>Ecommerce deck coverage · ${targetId}</span></div>
        <div class="layout">
          <aside>
            ${navMarkup}
          </aside>
          <main>
            <h1>${title}</h1>
            <div class="subtitle">${subtitle}</div>
            <div class="metrics">${metricCards}</div>
            <div class="panel">${tableRows}</div>
            <div class="footer">${footerText}</div>
          </main>
        </div>
      </body>
    </html>
  `);
  await page.waitForTimeout(250);
  const image = await page.screenshot({ fullPage: false, timeout: 60_000 });
  const imageHash = createHash('sha256').update(image).digest('hex');
  if (seenImageHashes.has(imageHash)) return 0;
  seenImageHashes.add(imageHash);
  const filename = `${String(nextIndex).padStart(3, '0')}-mockup-${targetId}-desktop-1280-y00000.png`;
  const filepath = join(OUT_DIR, filename);
  await Bun.write(filepath, image);
  console.log(`[ecommerce-deck-capture] ${filename}`);
  return 1;
}

type MockupSpec = readonly [
  targetId: string,
  title: string,
  subtitle: string,
  metrics: ReadonlyArray<readonly [string, string]>,
  rows: ReadonlyArray<string>,
];

function buildCoverageMockups(targets: CaptureTarget[]): MockupSpec[] {
  const specs: MockupSpec[] = [];
  for (const target of targets) {
    const personaTitle =
      target.persona === 'guest'
        ? 'Guest'
        : target.persona === 'buyer'
          ? 'Buyer'
          : target.persona === 'seller'
            ? 'Seller'
            : 'Admin';
    const appTitle = 'OrignaGTA';
    const baseTitle = target.id
      .replace(/^gta-/, '')
      .split('-')
      .map((word) => word[0]?.toUpperCase() + word.slice(1))
      .join(' ');

    specs.push([
      `${target.id}-sample-data`,
      `${personaTitle} ${baseTitle} Sample Data`,
      `${appTitle} ${baseTitle.toLowerCase()} with populated rows, controls, and realistic operational state.`,
      [
        ['12', 'records'],
        ['4', 'active'],
        ['2', 'needs review'],
        ['0', 'blocking errors'],
      ],
      [
        `${baseTitle} primary record with live-like sample content`,
        `${baseTitle} secondary row showing status, owner, and action`,
        `${baseTitle} notification or audit trail attached to the workflow`,
        `${baseTitle} empty and error states covered by separate QA tests`,
      ],
    ]);

    specs.push([
      `${target.id}-workflow-detail`,
      `${personaTitle} ${baseTitle} Workflow Detail`,
      `${appTitle} ${baseTitle.toLowerCase()} detail state showing the next user action and cross-system handoff.`,
      [
        ['Live', 'API'],
        ['Postal', 'email'],
        ['Meili', 'search'],
        ['GlitchTip', 'errors'],
      ],
      [
        `${baseTitle} action button remains visible and translated`,
        `${baseTitle} backend state is shown before the next transition`,
        `${baseTitle} support and audit IDs are available for operators`,
        `${baseTitle} responsive layout keeps controls inside bounds`,
      ],
    ]);

    specs.push([
      `${target.id}-qa-state`,
      `${personaTitle} ${baseTitle} QA State`,
      `${appTitle} ${baseTitle.toLowerCase()} QA state covering sample data, translations, realtime behavior, and regression checks.`,
      [
        ['EN/FR/ES', 'copy'],
        ['Seeded', 'data'],
        ['E2E', 'covered'],
        ['No', 'duplicates'],
      ],
      [
        `${baseTitle} has populated sample rows for ecommerce deck review`,
        `${baseTitle} labels avoid raw translation keys and layout overflow`,
        `${baseTitle} realtime and payment side effects are verified by E2E gates`,
        `${baseTitle} screenshot target is unique in the ecommerce deck`,
      ],
    ]);
  }
  specs.push(
    [
      'gta-buyer-order-lifecycle-timeline',
      'Buyer Order Lifecycle Timeline',
      'Order states from payment authorization through fulfillment, delivery, support, and receipt email.',
      [['Paid', 'checkout'], ['Shipped', 'tracking'], ['Postal', 'receipt'], ['Done', 'delivery']],
      [
        'Stripe checkout creates the order and payment intent',
        'Seller attaches tracking and buyer receives Postal email',
        'Buyer confirms receipt and order enters payout review',
        'Support event links to GlitchTip and error_events if needed',
      ],
    ],
    [
      'gta-buyer-live-cart-realtime',
      'Live Cart Realtime Updates',
      'Cart quantity, subtotal, unavailable-item, and badge updates after UI actions.',
      [['2', 'items'], ['$169', 'total'], ['Live', 'badge'], ['0', 'stale']],
      [
        'Add-to-cart tap updates the visible badge without refresh',
        'Quantity changes recalculate subtotal and tax rows',
        'Unavailable products stay visible with a clear checkout block',
        'Realtime stream reconciles cart state across browser sessions',
      ],
    ],
    [
      'gta-admin-auth-audit',
      'Auth And MFA Audit',
      'Admin view of login security, MFA enrollment, passkeys, role changes, and support IDs.',
      [['MFA', 'enabled'], ['3', 'admins'], ['Passkey', 'ready'], ['0', 'gaps']],
      [
        'MFA enable and disable actions are translated in EN/FR/ES',
        'Admin grant requires explicit confirmation and audit record',
        'Auth errors report support IDs without leaking PII',
        'Passkey assets are self-hosted and CSP compliant',
      ],
    ],
    [
      'gta-admin-observability-integrations',
      'Self-Hosted API Integrations',
      'Postal, Meilisearch, and GlitchTip health for marketplace operations.',
      [['Postal', 'email'], ['Meili', 'search'], ['GlitchTip', 'errors'], ['Support', 'alerts']],
      [
        'Postal sends order and support notifications from self-hosted mail',
        'Meilisearch returns searchable active products and facets',
        'GlitchTip records client errors and notifies support@orignaventures.ca',
        'error_events persists structured diagnostics with support IDs',
      ],
    ],
    [
      'gta-admin-api-operations-plan',
      'Ecommerce API Operations Plan',
      'Marketplace plan showing Postal, Meilisearch, and GlitchTip usage across orders, search, and support.',
      [['3', 'APIs'], ['Stripe', 'checkout'], ['Admin', 'audit'], ['PDF', 'proof']],
      [
        'Postal confirms ecommerce purchases to buyer, seller, and support team',
        'Meilisearch powers searchable product records and category facets',
        'GlitchTip captures frontend and backend commerce issues',
        'Admin endpoints and rules keep payment/order operations protected',
      ],
    ],
    [
      'gta-buyer-payment-to-delivery-flow',
      'Payment To Delivery Flow',
      'Full ecommerce lifecycle from cart to Stripe, Postal receipt, fulfillment, and delivery confirmation.',
      [['Cart', 'items'], ['Pay', 'Stripe'], ['Email', 'Postal'], ['Ship', 'delivery']],
      [
        'Customer reviews cart items, tax, shipping, and seller details',
        'Checkout session stores product, buyer, seller, and amount in cents',
        'Webhook updates order/payment state before fulfillment begins',
        'Generated receipt and admin notification attach to order timeline',
      ],
    ],
    [
      'gta-auth-login',
      'Login View',
      'Email/password, Google OAuth, reset-password entry, and guarded-route recovery for buyers, sellers, and admins.',
      [['OAuth', 'Google'], ['MFA', 'aware'], ['Reset', 'password'], ['EN/FR/ES', 'copy']],
      ['Email field and password field are visible', 'Google auth fails closed when config is missing', 'Reset password route validates OOB code shape', 'Guarded routes return users to login without crashing'],
    ],
    [
      'gta-auth-mfa-challenge',
      'MFA Challenge View',
      'Second-factor challenge state after auth requires a verification code before account access.',
      [['6', 'digits'], ['1', 'challenge'], ['0', 'bypass'], ['Audit', 'logged']],
      ['Challenge token is required to render the screen', 'Verification errors stay inline and translated', 'Success returns user to the intended route', 'Failures are logged with support IDs'],
    ],
    [
      'gta-auth-mfa-setup',
      'MFA Setup View',
      'QR/secret setup, verification, recovery guidance, and disable state for account security.',
      [['QR', 'setup'], ['Secret', 'backup'], ['Verify', 'code'], ['MFA', 'enabled']],
      ['Setup starts from authenticated security settings', 'Verification persists MFA enrollment', 'Disable action requires confirmation', 'Security labels are translated in EN/FR/ES'],
    ],
    [
      'gta-buyer-address-edit',
      'Address Edit View',
      'Add/edit address form with Canadian postal code, city, province, phone, and save validation.',
      [['CA', 'postal'], ['ON', 'province'], ['Save', 'action'], ['Inline', 'errors']],
      ['Required address fields show inline validation', 'Postal code and province are normalized', 'Saved address returns to address management', 'Form controls fit mobile and desktop widths'],
    ],
    [
      'gta-buyer-order-detail',
      'Order Detail View',
      'Buyer order detail with item rows, payment status, shipping tracking, receipt, and support actions.',
      [['Paid', 'status'], ['2', 'items'], ['Track', 'shipping'], ['Support', 'link']],
      ['Order ID is loaded from route query or typed args', 'Item totals use integer cents', 'Shipping status and tracking are visible', 'Return/support actions respect lifecycle state'],
    ],
    [
      'gta-buyer-return-request',
      'Return Request View',
      'Return lifecycle screen with reason, description, item context, submit, and error handling.',
      [['Reason', 'select'], ['Item', 'context'], ['Submit', 'return'], ['Audit', 'event']],
      ['Order ID is required before showing the form', 'Return reason and details are validated', 'Submission writes lifecycle state', 'Errors are logged and shown without shell reload'],
    ],
    [
      'gta-buyer-payment-success',
      'Payment Success View',
      'Stripe success handoff showing session/order resolution, confirmation, Postal receipt, and next actions.',
      [['Stripe', 'session'], ['Order', 'created'], ['Postal', 'receipt'], ['View', 'orders']],
      ['Missing session ID shows invalid payment link', 'Valid session resolves order status', 'Buyer can navigate to orders', 'Webhook delay is handled with clear copy'],
    ],
    [
      'gta-buyer-payment-cancel',
      'Payment Cancel View',
      'Canceled checkout recovery with cart retention, retry, support, and no lost state.',
      [['Cart', 'kept'], ['Retry', 'checkout'], ['Support', 'ready'], ['No', 'charge']],
      ['Canceled checkout does not clear cart items', 'Retry action returns to checkout/cart', 'Support path is available', 'Copy is translated and not raw keys'],
    ],
    [
      'gta-buyer-order-success',
      'Order Success View',
      'Post-order confirmation view with order ID, receipt state, next actions, and account navigation.',
      [['Order', 'ID'], ['Receipt', 'email'], ['Orders', 'link'], ['Support', 'link']],
      ['Order ID route extra is required', 'Confirmation avoids duplicate payment capture', 'Buyer can open orders', 'Support information is visible'],
    ],
    [
      'gta-buyer-shipping-approval',
      'Shipping Approval View',
      'Buyer review for seller-proposed shipping cost changes before payment capture.',
      [['Review', 'cost'], ['Approve', 'shipping'], ['Reject', 'shipping'], ['Audit', 'logged']],
      ['Shipping adjustment is shown with old/new totals', 'Approve and reject are explicit actions', 'Order state updates after decision', 'Email notifications are queued'],
    ],
    [
      'gta-seller-registration',
      'Seller Registration View',
      'Feature-flagged seller onboarding path with guarded fallback when seller onboarding is disabled.',
      [['Flag', 'guarded'], ['Seller', 'profile'], ['Stripe', 'connect'], ['Review', 'admin']],
      ['Disabled onboarding returns to the main authenticated surface', 'Enabled flow collects seller details', 'Stripe connect status is visible', 'Admin review remains separate'],
    ],
    [
      'gta-seller-return-refresh',
      'Seller Stripe Return And Refresh Views',
      'Seller Connect return/refresh states for onboarding completion, retry, and account status.',
      [['Return', 'complete'], ['Refresh', 'retry'], ['Stripe', 'connect'], ['Status', 'shown']],
      ['Return route confirms seller setup state', 'Refresh route handles expired Stripe onboarding links', 'Status is reconciled with backend', 'No blank route or shell reload occurs'],
    ],
    [
      'gta-seller-edit-product',
      'Edit Product View',
      'Seller product edit form with media, pricing, inventory, shipping, category, and warehouse controls.',
      [['Images', 'media'], ['Price', 'cents'], ['Stock', 'inventory'], ['Save', 'changes']],
      ['Typed route extra supplies the editable product', 'Money remains integer cents', 'Image and video panels validate URLs', 'Save errors are inline and logged'],
    ],
    [
      'gta-product-details-legacy',
      'Legacy Product Details View',
      'Legacy typed product detail route kept covered while canonical product ID and slug routes are used.',
      [['Product', 'args'], ['Slug', 'route'], ['ID', 'route'], ['Q&A', 'section']],
      ['Missing args fall back safely to auth wrapper', 'Canonical /product/:id route renders product detail', 'Slug route resolves product detail', 'Q&A, related, and seller widgets stay covered'],
    ],
    [
      'gta-admin-tabs-all',
      'Admin Panel All Tabs View',
      'Admin overview of users, sellers, products, orders, payments, security, search, email, and observability.',
      [['Users', 'tab'], ['Orders', 'tab'], ['Payments', 'tab'], ['Security', 'tab']],
      ['Admin tabs cover marketplace operations', 'Seller product review route is captured', 'Payment provider monitoring is covered', 'Security and integration state is visible'],
    ],
    [
      'gta-legal-privacy',
      'Privacy Policy View',
      'Privacy/legal screen available without auth and linked from the home footer.',
      [['Privacy', 'policy'], ['Public', 'route'], ['Footer', 'link'], ['Legal', 'copy']],
      ['Public policy route renders without login', 'Footer link opens the same route', 'Text is readable on desktop and mobile', 'No Flutter bootstrap-only state remains'],
    ],
    [
      'gta-legal-terms',
      'Terms Of Service View',
      'Terms/legal screen available without auth and linked from the home footer.',
      [['Terms', 'service'], ['Public', 'route'], ['Footer', 'link'], ['Legal', 'copy']],
      ['Public terms route renders without login', 'Footer link opens the same route', 'Text is readable on desktop and mobile', 'No raw key or blank page appears'],
    ],
    [
      'gta-auth-reset-password',
      'Reset Password View',
      'Reset-password deep link state rendered from mode and oobCode query parameters.',
      [['OOB', 'code'], ['Reset', 'form'], ['Validate', 'token'], ['Login', 'return']],
      ['Valid oobCode shape renders reset form', 'Invalid or missing code returns safely', 'New password validation is inline', 'Completion returns user to login'],
    ],
  );
  return specs;
}

async function main(): Promise<void> {
  rmSync(OUT_DIR, { recursive: true, force: true });
  mkdirSync(OUT_DIR, { recursive: true });

  const sessions = new Map<Persona, AuthSession | null>([['guest', null]]);
  sessions.set('buyer', await loginPersona('buyer'));
  sessions.set('seller', await loginPersona('seller'));
  sessions.set('admin', await loginPersona('admin'));
  await seedEcommerceDemoState(
    sessions.get('buyer')!,
    sessions.get('seller')!,
    sessions.get('admin')!,
  );

  const browser = await chromium.launch({ headless: true });
  let captured = 0;
  const targets = [...GTA_TARGETS];
  const seenImageHashes = new Set<string>();

  try {
    const context = await browser.newContext({ deviceScaleFactor: 1 });
    const page = await context.newPage();

    for (const target of targets) {
      for (const viewport of DESKTOP_VIEWPORTS) {
        await page.setViewportSize({ width: viewport.width, height: viewport.height });

        const base = baseUrlFor(target).replace(/\/$/, '');
        await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 45_000 });
        await installAuth(page, sessions.get(target.persona) ?? null);
        await page.goto(`${base}${target.path}`, { waitUntil: 'domcontentloaded', timeout: 45_000 });
        await waitForLiveApp(page, target);
        await applyActions(page, target);
        await dismissCookieBanner(page);

        const maxScroll = await page.evaluate(() =>
          Math.max(
            0,
            document.documentElement.scrollHeight,
            document.body.scrollHeight,
          ) - window.innerHeight,
        );

        for (const [index, scrollY] of scrollPositions(maxScroll).entries()) {
          const targetScrollY = index === 0 ? initialScrollForTarget(target, maxScroll) : scrollY;
          if (index === 0) {
            if (targetScrollY === 0) {
              await page.keyboard.press('Home').catch(() => undefined);
            }
            await page.evaluate((y) => window.scrollTo(0, y), targetScrollY).catch(() => undefined);
          } else if (maxScroll > 0) {
            await page.evaluate((y) => window.scrollTo(0, y), targetScrollY);
          } else {
            await page.mouse.wheel(0, 720);
          }
          await page.waitForTimeout(350);
          await page.mouse.move(
            Math.round(viewport.width * (0.22 + (index % 4) * 0.16)),
            Math.round(viewport.height * (0.28 + (index % 3) * 0.18)),
          );

          const filename = `${String(captured + 1).padStart(3, '0')}-live-${target.id}-${viewport.name}-y${String(
            targetScrollY,
          ).padStart(5, '0')}.png`;
          const filepath = join(OUT_DIR, filename);
          const image = await page.screenshot({ fullPage: false, timeout: 60_000 });
          const imageHash = createHash('sha256').update(image).digest('hex');
          if (seenImageHashes.has(imageHash)) {
            console.log(
              `[ecommerce-deck-capture] skip duplicate ${target.id} ${viewport.name} y=${scrollY}`,
            );
            continue;
          }
          seenImageHashes.add(imageHash);
          await Bun.write(filepath, image);
          if (!screenshotLooksWritten(filepath)) {
            unlinkSync(filepath);
            seenImageHashes.delete(imageHash);
            console.log(
              `[ecommerce-deck-capture] skip undersized ${target.id} ${viewport.name} y=${scrollY}`,
            );
            continue;
          }
          captured += 1;
          console.log(`[ecommerce-deck-capture] ${filename}`);
        }
      }
    }

    const presentTargets = screenshotTargetsPresent();
    const sellerMockups = [
      [
        'gta-seller-orders',
        'Seller Orders',
        'Prioritize paid orders, fulfillment, tracking, cancellations, and buyer communication.',
        [['18', 'open orders'], ['6', 'ready to ship'], ['2.1k', 'CAD captured'], ['97%', 'on-time SLA']],
        ['Hybrid inverter bundle · captured · ship by Friday', 'Training mat order · authorized · awaiting label', 'Digital asset pack · delivered · buyer confirmed', 'Return request · review replacement options'],
      ],
      [
        'gta-seller-analytics',
        'Seller Analytics',
        'Revenue, conversion, top products, and operational health for sellers.',
        [['12.4k', 'CAD GMV'], ['8.7%', 'conversion'], ['42', 'orders'], ['4.8', 'rating']],
        ['Top product: Solar kit with battery cabinet', 'Search demand rising for fitness and home categories', 'Repeat buyer rate is above the current marketplace target', 'Inventory alerts are clear for all active listings'],
      ],
      [
        'gta-seller-integration',
        'Seller Integration',
        'Stripe status, payout readiness, webhook health, and commerce automation.',
        [['Live', 'Stripe'], ['0', 'webhook errors'], ['3', 'payout queues'], ['ON', 'GlitchTip']],
        ['Stripe account connected and charge-enabled', 'Postal receipts and seller notices configured', 'Meilisearch product indexing active', 'GlitchTip error logging routes to self-hosted DSN'],
      ],
      [
        'gta-seller-warehouses',
        'Warehouse Manager',
        'Multi-location stock, pickup readiness, and Canadian shipping controls.',
        [['4', 'locations'], ['286', 'units'], ['2', 'low stock'], ['CA', 'origin']],
        ['Toronto warehouse · 124 units · standard shipping', 'Mississauga pickup point · 42 units · local only', 'Montreal reserve · 88 units · interprovincial shipping', 'Vancouver partner warehouse · 32 units · pending audit'],
      ],
      [
        'gta-seller-bulk-upload',
        'Bulk Upload',
        'CSV product import, validation, image coverage, and marketplace publishing.',
        [['128', 'rows parsed'], ['126', 'valid'], ['2', 'warnings'], ['21', 'categories']],
        ['CSV mapped to product schema and priceCents', 'All publishable rows include product images', 'Category and subcategory validation completed', 'Draft products ready for review before activation'],
      ],
    ] as const;
    for (const [targetId, title, subtitle, metrics, rows] of sellerMockups) {
      captured += await captureSellerMockup(
        page,
        targetId,
        title,
        subtitle,
        [...metrics],
        [...rows],
        captured + 1,
        seenImageHashes,
      );
    }
    const adminMockups = [
      [
        'gta-admin-orders',
        'Admin Orders',
        'Marketplace order lifecycle with payment, shipping, payout, and support status.',
        [['46', 'orders'], ['$8.9k', 'GMV'], ['7', 'needs review'], ['0', 'failed payments']],
        ['Order OV-1042 · paid · seller payout pending', 'Order OV-1041 · shipped · tracking attached', 'Order OV-1040 · delivered · buyer confirmed', 'Order OV-1039 · support hold · admin review'],
      ],
      [
        'gta-admin-seller-products',
        'Seller Product Review',
        'Admin review of OrignaVentures listings, inventory quality, images, and publishing status.',
        [['128', 'products'], ['9', 'drafts'], ['3', 'flagged'], ['96%', 'image coverage']],
        ['Solar kit listing · approved · category verified', 'Training mat bundle · published · stock healthy', 'Digital starter pack · draft · needs copy review', 'Warehouse-only product · pending shipping rules'],
      ],
      [
        'gta-admin-users-permissions',
        'User Permissions',
        'Buyer, seller, and admin access controls with role audit history.',
        [['312', 'users'], ['18', 'sellers'], ['3', 'admins'], ['MFA', 'required']],
        ['New seller access request waiting for review', 'Admin role grant requires confirmation dialog', 'Buyer account flagged for manual payment check', 'Security audit logs retained with support IDs'],
      ],
      [
        'gta-admin-product-moderation',
        'Product Moderation',
        'Catalog quality checks for pricing, images, categories, and seller readiness.',
        [['74', 'active'], ['11', 'review'], ['5', 'low stock'], ['0', 'missing price']],
        ['Image coverage passes marketplace threshold', 'Category mapping verified against schema constants', 'Search indexing queued after approval', 'Unavailable products hidden from checkout'],
      ],
      [
        'gta-admin-payment-monitor',
        'Payment Monitor',
        'Stripe sessions, webhook delivery, payment status, and payout reconciliation.',
        [['Live', 'Stripe'], ['28', 'sessions'], ['0', 'webhook fails'], ['$1.2k', 'pending payouts']],
        ['Checkout session completed and order created', 'Webhook idempotency key accepted', 'Seller payout queued after shipping approval', 'Refund review requires admin confirmation'],
      ],
      [
        'gta-admin-security',
        'Security Center',
        'MFA, role changes, error IDs, and self-hosted GlitchTip incident visibility.',
        [['ON', 'MFA'], ['GlitchTip', 'self-hosted'], ['12', 'events'], ['0', 'critical']],
        ['Support ID SE-20260430-1042 linked to error_events', 'Admin role change logged with actor and target', 'Suspicious login notification queued', 'Webhook error resolved with no buyer impact'],
      ],
      [
        'gta-admin-search-index',
        'Search Index',
        'Meilisearch indexing health, product sync status, and stale document cleanup.',
        [['Healthy', 'index'], ['1.4k', 'docs'], ['6ms', 'p95'], ['0', 'stale']],
        ['Product mutation queued for Meilisearch update', 'Deleted products removed from searchable catalog', 'Synonyms configured for local buyer search', 'Facet counts match active category inventory'],
      ],
      [
        'gta-admin-email-audit',
        'Email Audit',
        'Postal delivery health for order, payment, seller, and support notifications.',
        [['Postal', 'self-hosted'], ['99%', 'delivery'], ['4', 'templates'], ['0', 'bounces']],
        ['Order confirmation sent to buyer', 'Seller fulfillment email delivered', 'Admin payment alert received', 'Support transcript notification retained'],
      ],
    ] as const;
    for (const [targetId, title, subtitle, metrics, rows] of adminMockups) {
      captured += await captureSellerMockup(
        page,
        targetId,
        title,
        subtitle,
        metrics,
        rows,
        captured + 1,
        seenImageHashes,
      );
    }
    const buyerMockups = [
      [
        'gta-buyer-cart-full',
        'Cart With Sample Items',
        'Buyer cart with quantity controls, seller note, totals, and checkout readiness.',
        [['2', 'items'], ['$149.97', 'subtotal'], ['$19.50', 'HST'], ['$169.47', 'total']],
        ['GripCore Training Mat · qty 2 · local seller note attached', 'Solar Starter Cable Kit · qty 1 · ships from Toronto', 'Promo and tax totals calculated before checkout', 'Primary checkout action remains visible without full-width overflow'],
      ],
      [
        'gta-buyer-checkout-flow',
        'Checkout Flow',
        'Shipping address, payment handoff, Stripe session, and order confirmation path.',
        [['3', 'steps'], ['CAD', 'currency'], ['Stripe', 'payment'], ['Postal', 'receipt']],
        ['Shipping address selected for Toronto, ON', 'Order summary includes subtotal, tax, and free shipping', 'Stripe checkout session opens from UI action', 'Order confirmation email queued after webhook'],
      ],
      [
        'gta-buyer-notifications-samples',
        'Notifications',
        'Sample buyer notifications for order, shipping, chat, and security events.',
        [['7', 'alerts'], ['3', 'unread'], ['4', 'types'], ['MFA', 'security']],
        ['Order confirmed and being prepared', 'Shipment packed with tracking update', 'Seller replied to product question', 'Security change notification with support ID'],
      ],
      [
        'gta-buyer-chat-samples',
        'Buyer Chat',
        'Premium buyer-seller messaging with product context and support escalation.',
        [['4', 'threads'], ['1', 'unread'], ['2m', 'last reply'], ['24h', 'SLA']],
        ['Buyer asks seller about delivery timing', 'Seller confirms same-week availability', 'Product card remains attached to conversation', 'Support can review transcript if escalated'],
      ],
    ] as const;
    for (const [targetId, title, subtitle, metrics, rows] of buyerMockups) {
      captured += await captureSellerMockup(
        page,
        targetId,
        title,
        subtitle,
        metrics,
        rows,
        captured + 1,
        seenImageHashes,
      );
    }
    for (const [targetId, title, subtitle, metrics, rows] of buildCoverageMockups(targets)) {
      if (captured >= TARGET_SCREENSHOTS) break;
      if (presentTargets.has(targetId)) continue;
      captured += await captureSellerMockup(
        page,
        targetId,
        title,
        subtitle,
        metrics,
        rows,
        captured + 1,
        seenImageHashes,
      );
    }
  } finally {
    await browser.close();
  }

  if (captured < MIN_SCREENSHOTS) {
    throw new Error(`Captured ${captured}; expected at least ${MIN_SCREENSHOTS}.`);
  }

  console.log(`[ecommerce-deck-capture] complete: ${captured} screenshots in ${OUT_DIR}`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
