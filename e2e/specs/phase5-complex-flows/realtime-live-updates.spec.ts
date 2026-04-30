import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';

import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  callOk,
  deleteDoc,
  listCollection,
  signIn,
  writeDoc,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_PRODUCTS, WEB_APP_URL } from '../../lib/config.js';

const PRODUCT_ID = TEST_PRODUCTS.HIGH_STOCK;

async function waitForSnapshotText(
  browser: AgentBrowser,
  pattern: RegExp,
  timeoutMs = 30_000,
): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  let latest = '';
  while (Date.now() < deadline) {
    const snap = await browser.snapshot({ interactive: true });
    latest = snap.raw;
    if (pattern.test(snap.raw)) return snap.raw;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Timed out waiting for ${pattern}; latest=${latest.slice(0, 1200)}`);
}

function uid(prefix: string): string {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

async function openAuthed(browser: AgentBrowser, route: string): Promise<void> {
  await browser.loginViaApi(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
  await browser.open(`${WEB_APP_URL}${route}`);
  await browser.waitForFlutter();
}

async function clearBuyerNotifications(token: string, localUserId: string): Promise<void> {
  const notifications = await listCollection(`users/${localUserId}/notifications`, token);
  await Promise.all(
    notifications.map((notification) => {
      const id = String(notification.id ?? '');
      return id ? deleteDoc(`users/${localUserId}/notifications/${id}`, token).catch(() => false) : false;
    }),
  );
}

describe('Realtime Live Updates', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  beforeEach(async () => {
    await browser.clearState();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('notifications page receives a live subcollection insert without refresh', { timeout: 90_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const notificationId = uid('rt_notification');
    await clearBuyerNotifications(auth.idToken, auth.localId);

    await openAuthed(browser, '/notifications');
    await waitForSnapshotText(browser, /btn-back|btn-mascot-tap/i);

    const ok = await writeDoc(
      `users/${auth.localId}/notifications/${notificationId}`,
      {
        uid: auth.localId,
        userId: auth.localId,
        title: `Realtime notification ${notificationId}`,
        body: 'Created by the live realtime E2E audit.',
        type: 'account_update',
        isRead: false,
        createdAt: '2000-01-01T00:00:00.000Z',
      },
      auth.idToken,
      false,
    );
    expect(ok).toBe(true);

    try {
      await waitForSnapshotText(browser, /btn-mark-all-read|Mark all read/i, 35_000);
    } finally {
      await deleteDoc(`users/${auth.localId}/notifications/${notificationId}`, auth.idToken).catch(() => false);
    }
  });

  test('favorites page receives a live favorite insert without refresh', { timeout: 90_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const favoriteId = `rt_favorite_${auth.localId}_${PRODUCT_ID}`.replace(/[^a-zA-Z0-9_-]/g, '_');

    await deleteDoc(`favorites/${favoriteId}`, auth.idToken).catch(() => false);
    await openAuthed(browser, '/favorites');
    await waitForSnapshotText(browser, /favorites|favoris|favoritos|empty|vide|vac/i);

    const ok = await writeDoc(
      `favorites/${favoriteId}`,
      {
        uid: auth.localId,
        userId: auth.localId,
        productId: PRODUCT_ID,
        createdAt: '2000-01-01T00:00:00.000Z',
      },
      auth.idToken,
      false,
    );
    expect(ok).toBe(true);

    try {
      await waitForSnapshotText(
        browser,
        new RegExp(`card-favorite-product-${PRODUCT_ID}|${PRODUCT_ID}`, 'i'),
        35_000,
      );
    } finally {
      await deleteDoc(`favorites/${favoriteId}`, auth.idToken).catch(() => false);
    }
  });

  test('orders page receives a live captured order insert without refresh', { timeout: 90_000 }, async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const admin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const orderId = uid('rt_order');
    const itemName = `Realtime Audit Item ${orderId}`;

    await openAuthed(browser, '/orders');
    await waitForSnapshotText(browser, /tab-order-filter-All|orders-start-shopping|btn-back/i);

    const ok = await writeDoc(
      `orders/${orderId}`,
      {
        orderId,
        userId: buyer.localId,
        buyerId: buyer.localId,
        customerEmail: TEST_ACCOUNTS.BUYER_EMAIL,
        items: [
          {
            productId: PRODUCT_ID,
            cartItemId: `${orderId}_item`,
            name: itemName,
            description: 'Live realtime E2E audit order item',
            priceCents: 1299,
            quantity: 1,
            imageUrls: [],
            sellerId: admin.localId,
            sellerName: 'OrignaGTA E2E Seller',
            status: 'pending',
          },
        ],
        totalAmountCents: 1468,
        subtotalCents: 1299,
        shippingCostCents: 0,
        taxAmountCents: 169,
        taxes: { gstCents: 0, pstCents: 0, qstCents: 0, hstCents: 169 },
        orderStatus: 'confirmed',
        paymentStatus: 'captured',
        createdAt: '2000-01-01T00:00:00.000Z',
        currency: 'CAD',
        sellerIds: [admin.localId],
        productIds: [PRODUCT_ID],
      },
      admin.idToken,
      false,
    );
    expect(ok).toBe(true);

    await waitForSnapshotText(browser, new RegExp(`btn-cancel-order-${orderId}|order-card-${orderId}|${itemName}`, 'i'), 35_000);
  });

  test('cart badge still updates from live UI add-to-cart interactions', { timeout: 120_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await callOk('clear_cart', {}, auth.idToken).catch(() => null);

    await openAuthed(browser, '/');
    const first = await browser.waitForChange({ text: /btn-add-to-cart-|add.*cart|panier/i, timeout: 30_000 });
    const addButton = browser.findByLabel(first, /btn-add-to-cart-|add.*cart|panier/i);
    expect(addButton).toBeTruthy();

    await browser.click(addButton!.ref);
    await waitForSnapshotText(browser, /btn-cart[^\\n]*(1)|cart[^\\n]*(1)|panier[^\\n]*(1)/i, 35_000);
  });
});
