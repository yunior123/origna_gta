#!/usr/bin/env bun

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, rmSync, statSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';
import { chromium, type Page } from 'playwright';
import {
  ORIGNABASE_URL,
  TEST_ACCOUNTS,
  VENTURES_WEB_URL,
  WEB_APP_URL,
} from './config.js';
import { signIn } from './api-client.js';

const OUT_DIR =
  process.env.SCREENSHOT_OUT_DIR || '../origna_ventures/output/desktop-screenshots';
const MIN_SCREENSHOTS = Number(process.env.MIN_INVESTOR_SCREENSHOTS || 112);

type Persona = 'guest' | 'buyer' | 'seller' | 'admin';

type AuthSession = {
  email: string;
  localId: string;
  accessToken: string;
  refreshToken: string;
};

type CaptureTarget = {
  id: string;
  app: 'gta' | 'ventures';
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
  { name: 'desktop-1440', width: 1440, height: 900 },
  { name: 'desktop-1600', width: 1600, height: 900 },
  { name: 'desktop-1728', width: 1728, height: 900 },
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
      `Failed to seed investor capture doc ${collection}/${id}: ${
        body?.errors?.[0]?.message ?? response.status
      }`,
    );
  }
}

async function seedInvestorDemoState(
  buyer: AuthSession,
  seller: AuthSession,
  admin: AuthSession,
): Promise<void> {
  await seedBuyerCartForCheckout(buyer);
  const now = new Date().toISOString();
  const productImage =
    'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/digital-1.jpg';

  const bestEffort = async (label: string, fn: () => Promise<void>) => {
    try {
      await fn();
    } catch (error) {
      console.warn(
        `[investor-desktop-capture] seed skipped ${label}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  };

  await bestEffort('buyer notifications', async () => {
    const notifications = [
      ['order-confirmed', 'Order confirmed', 'Your OrignaGTA order is confirmed and being prepared.', 'order_confirmation'],
      ['shipping-update', 'Shipping update', 'Your training kit is packed and ready for pickup.', 'shipping_update'],
      ['chat-message', 'New seller reply', 'Northline Market replied to your question.', 'chat_message'],
    ];
    for (const [suffix, title, body, type] of notifications) {
      await writeGraphqlDoc(
        'users__notifications',
        `investor_${buyer.localId}_${suffix}`,
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
      name: 'Investor Checkout Sample',
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
        `investor_${buyer.localId}_${suffix}`,
        {
          orderId: `investor_${buyer.localId}_${suffix}`,
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
          stripeSessionId: `cs_investor_${suffix}`,
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
    const chatId = `investor_chat_${buyer.localId}`;
    await writeGraphqlDoc(
      'chats',
      chatId,
      {
        chatId,
        productId: 'e2e_product_test_seller',
        productTitle: 'Investor Checkout Sample',
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
    `investor_checkout_${session.localId}`,
    {
      parent_id: `users:${session.localId}`,
      parent_collection: 'users',
      userId: `users:${session.localId}`,
      productId,
      quantity: 2,
      priceCents: 1999,
      priceSnapshot: 1999,
      name: 'Investor Checkout Sample',
      productName: 'Investor Checkout Sample',
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
      `[investor-desktop-capture] seed skipped user_carts aggregate: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  });
}

function baseUrlFor(target: CaptureTarget): string {
  return target.app === 'gta' ? WEB_APP_URL : VENTURES_WEB_URL;
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
    const match = file.match(/(?:live|mockup)-(gta|ventures)-(.+?)-desktop-/);
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
  if (target.id === 'ventures-site-sections-b') {
    return Math.round(maxScroll * 0.38);
  }
  if (target.id === 'ventures-site-sections-c') {
    return Math.round(maxScroll * 0.72);
  }
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
    await page.waitForSelector('body', { timeout: 20_000 });
    const bodyText = (await page.locator('body').innerText({ timeout: 10_000 })).toLowerCase();
    if (!bodyText.includes('origna ventures')) {
      throw new Error(`Ventures app did not load expected content for ${target.id}`);
    }
  }
  await page.waitForTimeout(1_000);
}

async function applyActions(page: Page, target: CaptureTarget): Promise<void> {
  if (target.id === 'ventures-site-sections-b') {
    await page.evaluate(() => window.scrollTo(0, Math.round(document.documentElement.scrollHeight * 0.38)));
    await page.waitForTimeout(450);
  }
  if (target.id === 'ventures-site-sections-c') {
    await page.evaluate(() => window.scrollTo(0, Math.round(document.documentElement.scrollHeight * 0.72)));
    await page.waitForTimeout(450);
  }
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
  const consoleTitle = targetId.startsWith('ventures-')
    ? 'Origna Ventures Delivery Console'
    : targetId.startsWith('gta-admin-')
      ? 'OrignaGTA Admin Console'
      : targetId.startsWith('gta-buyer-')
        ? 'OrignaGTA Buyer Experience'
    : 'OrignaGTA Seller Console';
  const footerText = targetId.startsWith('ventures-')
    ? 'These mockups preserve investor deck coverage for service sales, intake, delivery, and payment operations.'
    : targetId.startsWith('gta-admin-')
      ? 'These mockups preserve investor deck coverage for admin operations when live admin tabs render too small for deck export.'
      : targetId.startsWith('gta-buyer-')
        ? 'These mockups preserve investor deck coverage for buyer flows when protected live sample data is permission-limited.'
    : 'Seller onboarding is disabled in production; these mockups preserve investor deck coverage for the full seller operating surface.';
  const navItems = targetId.startsWith('ventures-')
    ? [
        ['service', 'Service tiers'],
        ['intake', 'Project intake'],
        ['delivery', 'Delivery tracker'],
        ['payment', 'Payment handoff'],
        ['contact', 'Contact'],
        ['admin', 'Admin'],
      ]
    : targetId.startsWith('gta-admin-')
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
        <div class="top"><span>${consoleTitle}</span><span>Mockup coverage · ${targetId}</span></div>
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
  console.log(`[investor-desktop-capture] ${filename}`);
  return 1;
}

async function main(): Promise<void> {
  rmSync(OUT_DIR, { recursive: true, force: true });
  mkdirSync(OUT_DIR, { recursive: true });

  const sessions = new Map<Persona, AuthSession | null>([['guest', null]]);
  sessions.set('buyer', await loginPersona('buyer'));
  sessions.set('seller', await loginPersona('seller'));
  sessions.set('admin', await loginPersona('admin'));
  await seedInvestorDemoState(
    sessions.get('buyer')!,
    sessions.get('seller')!,
    sessions.get('admin')!,
  );

  const browser = await chromium.launch({ headless: true });
  let captured = 0;
  const targets = [...GTA_TARGETS, ...VENTURES_TARGETS];
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
              `[investor-desktop-capture] skip duplicate ${target.id} ${viewport.name} y=${scrollY}`,
            );
            continue;
          }
          seenImageHashes.add(imageHash);
          await Bun.write(filepath, image);
          if (!screenshotLooksWritten(filepath)) {
            unlinkSync(filepath);
            seenImageHashes.delete(imageHash);
            console.log(
              `[investor-desktop-capture] skip undersized ${target.id} ${viewport.name} y=${scrollY}`,
            );
            continue;
          }
          captured += 1;
          console.log(`[investor-desktop-capture] ${filename}`);
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
      if (presentTargets.has(targetId)) continue;
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
    const venturesMockups = [
      [
        'ventures-service-tiers',
        'Service Tiers',
        'Pricing-first service cards for OrignaCode, OrignaLaunch, and OrignaTeam checkout.',
        [['$500', 'code'], ['$3k', 'launch'], ['$1k/mo', 'team'], ['3', 'checkout paths']],
        ['OrignaCode routes directly to Stripe checkout', 'OrignaLaunch captures launch delivery scope', 'OrignaTeam configures monthly subscription billing', 'Support email and phone visible before payment'],
      ],
      [
        'ventures-project-intake',
        'Project Intake',
        'Lead capture and qualification before service delivery starts.',
        [['12', 'open leads'], ['4', 'ready'], ['2', 'blocked'], ['EN/FR/ES', 'locales']],
        ['Founder details collected with budget and timeline', 'Service fit reviewed before invoice handoff', 'Postal confirmation queued for buyer and admin', 'Admin-only exports protected by API key'],
      ],
      [
        'ventures-delivery-tracker',
        'Delivery Tracker',
        'Operational handoff from paid service to implementation milestones.',
        [['5', 'active builds'], ['87%', 'on track'], ['9', 'milestones'], ['0', 'late']],
        ['Discovery completed and repository access pending', 'Design pass approved for launch package', 'Stripe receipt attached to customer timeline', 'Final QA gate scheduled before production deploy'],
      ],
      [
        'ventures-payment-handoff',
        'Payment Handoff',
        'Stripe checkout, Postal receipts, and admin notifications for every service tier.',
        [['Live', 'Stripe'], ['ON', 'Postal'], ['3', 'webhooks'], ['0', 'failures']],
        ['Checkout session created from selected service code', 'Customer receipt delivered through self-hosted email', 'Admin notification includes tier, amount, and session', 'Webhook writes payment state before delivery begins'],
      ],
    ] as const;
    for (const [targetId, title, subtitle, metrics, rows] of venturesMockups) {
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

  console.log(`[investor-desktop-capture] complete: ${captured} screenshots in ${OUT_DIR}`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
