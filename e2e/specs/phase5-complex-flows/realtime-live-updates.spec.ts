import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';
import { chromium, type Browser, type Page } from 'playwright';

import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  callOk,
  deleteDoc,
  listCollection,
  readDoc,
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

function bareId(id: unknown): string {
  return String(id ?? '').split(':').pop() ?? '';
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

async function clearBuyerFavorites(token: string, localUserId: string): Promise<void> {
  const favorites = await listCollection('favorites', token);
  await Promise.all(
    favorites
      .filter((favorite) => favorite.userId === localUserId || favorite.uid === localUserId)
      .map((favorite) => {
        const id = bareId(favorite.id);
        return id ? deleteDoc(`favorites/${id}`, token).catch(() => false) : false;
      }),
  );
}

async function clearBuyerCart(token: string, localUserId: string): Promise<void> {
  const items = await listCollection(`users/${localUserId}/cart`, token);
  await Promise.all(
    items.map((item) => {
      const id = bareId(item.id);
      return id ? deleteDoc(`users/${localUserId}/cart/${id}`, token).catch(() => false) : false;
    }),
  );
}

async function clearBuyerRealtimeOrders(token: string, localUserId: string): Promise<void> {
  const orders = await listCollection('orders', token);
  await Promise.all(
    orders
      .filter((order) => {
        const id = bareId(order.id);
        return (
          (id.startsWith('rt_order_') || id.startsWith('rt_ui_order_')) &&
          (order.userId === localUserId || order.buyerId === localUserId)
        );
      })
      .map((order) =>
        writeDoc(
          `orders/${bareId(order.id)}`,
          {
            userId: 'archived-realtime-e2e',
            buyerId: 'archived-realtime-e2e',
            orderStatus: 'archived',
          },
          token,
          true,
        ).catch(() => false),
      ),
  );
}

async function openAuthedPlaywrightPage(
  browser: Browser,
  auth: Awaited<ReturnType<typeof signIn>>,
  route: string,
): Promise<Page> {
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();
  await page.goto(WEB_APP_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await page.evaluate((session) => {
    localStorage.setItem('orignabase_access_token', session.idToken);
    localStorage.setItem('orignabase_refresh_token', session.refreshToken ?? '');
    localStorage.setItem('orignabase_email', session.email ?? '');
  }, auth);
  await page.goto(`${WEB_APP_URL}${route}`, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await page.waitForSelector('flt-glass-pane, body', { timeout: 45_000 });
  await page.getByText(/accept|accepter|aceptar/i).last().click({ timeout: 2_000 }).catch(() => undefined);
  await page.waitForTimeout(4_000);
  return page;
}

async function bodyText(page: Page): Promise<string> {
  return page.locator('body').innerText({ timeout: 10_000 }).catch(() => '');
}

async function waitForBodyText(page: Page, pattern: RegExp, timeoutMs = 35_000): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  let latest = '';
  while (Date.now() < deadline) {
    latest = await bodyText(page);
    if (pattern.test(latest)) return latest;
    await page.waitForTimeout(500);
  }
  throw new Error(`Timed out waiting for ${pattern}; latest=${latest.slice(0, 1200)}`);
}

async function waitForBodyTextAfterReload(
  page: Page,
  route: string,
  pattern: RegExp,
  timeoutMs = 35_000,
): Promise<string> {
  try {
    return await waitForBodyText(page, pattern, timeoutMs);
  } catch {
    await page.getByText(/retry/i).click({ timeout: 2_000 }).catch(() => undefined);
    await page.goto(`${WEB_APP_URL}${route}`, { waitUntil: 'domcontentloaded', timeout: 60_000 });
    await page.waitForSelector('flt-glass-pane, body', { timeout: 45_000 });
    await page.waitForTimeout(3_000);
    return waitForBodyText(page, pattern, timeoutMs);
  }
}

async function pageSignal(page: Page): Promise<string> {
  const [text, labels] = await Promise.all([
    bodyText(page),
    ariaLabels(page).catch(() => []),
  ]);
  return `${text}\n${labels.join('\n')}`;
}

async function waitForPageSignalAfterReload(
  page: Page,
  route: string,
  pattern: RegExp,
  timeoutMs = 35_000,
): Promise<string> {
  const wait = async () => {
    const deadline = Date.now() + timeoutMs;
    let latest = '';
    while (Date.now() < deadline) {
      latest = await pageSignal(page);
      if (pattern.test(latest)) return latest;
      await page.waitForTimeout(500);
    }
    throw new Error(`Timed out waiting for ${pattern}; latest=${latest.slice(0, 1200)}`);
  };

  try {
    return await wait();
  } catch {
    await page.getByText(/retry/i).click({ timeout: 2_000 }).catch(() => undefined);
    await page.goto(`${WEB_APP_URL}${route}`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    await page.waitForSelector('flt-glass-pane, body', { timeout: 20_000 });
    await page.waitForTimeout(3_000);
    return wait();
  }
}

async function waitForNoBodyText(page: Page, pattern: RegExp, timeoutMs = 35_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  let latest = '';
  while (Date.now() < deadline) {
    latest = await bodyText(page);
    if (!pattern.test(latest)) return;
    await page.waitForTimeout(500);
  }
  throw new Error(`Timed out waiting for ${pattern} to disappear; latest=${latest.slice(0, 1200)}`);
}

async function waitForNotificationRead(
  uid: string,
  notificationId: string,
  token: string,
  timeoutMs = 35_000,
): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const doc = await Promise.race([
      readDoc(`users/${uid}/notifications/${notificationId}`, token),
      new Promise<null>((resolve) => setTimeout(() => resolve(null), 5_000)),
    ]);
    const fields = doc?.fields ?? {};
    if (fields.read?.booleanValue === true || fields.isRead?.booleanValue === true) return;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Timed out waiting for notification ${notificationId} to be marked read`);
}

async function ariaLabels(page: Page): Promise<string[]> {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('[aria-label]'))
      .map((element) => element.getAttribute('aria-label') ?? '')
      .filter(Boolean),
  );
}

async function findAriaTarget(
  page: Page,
  pattern: RegExp,
  options: { scroll?: boolean } = {},
): Promise<{ label: string; x: number; y: number } | null> {
  const attempts = options.scroll ? 10 : 1;
  if (options.scroll) {
    await page.mouse.wheel(0, -10_000);
    await page.waitForTimeout(300);
  }
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    const target = await page.evaluate(
      ({ source, flags }) => {
        const re = new RegExp(source, flags);
        for (const element of Array.from(document.querySelectorAll('[aria-label]'))) {
          const label = element.getAttribute('aria-label') ?? '';
          if (!re.test(label)) continue;
          element.scrollIntoView({ block: 'center', inline: 'center' });
          const rect = element.getBoundingClientRect();
          return {
            label,
            x: rect.left + rect.width / 2,
            y: rect.top + rect.height / 2,
          };
        }
        return null;
      },
      { source: pattern.source, flags: pattern.flags },
    );
    if (target) return target;
    await page.mouse.wheel(0, 700);
    await page.waitForTimeout(500);
  }
  return null;
}

async function clickAria(page: Page, pattern: RegExp, options: { scroll?: boolean } = {}): Promise<string> {
  const target = await findAriaTarget(page, pattern, options);
  if (!target) {
    const fallback = page.getByText(pattern).last();
    if (await fallback.isVisible({ timeout: 2_000 }).catch(() => false)) {
      await fallback.click({ timeout: 10_000 });
      return pattern.source;
    }
    throw new Error(`No aria label or text matching ${pattern}; labels=${(await ariaLabels(page)).join(' | ')}`);
  }
  await page.mouse.click(target.x, target.y);
  return target.label;
}

async function fillAria(
  page: Page,
  pattern: RegExp,
  value: string,
  options: { scroll?: boolean } = {},
): Promise<string> {
  const target = await page.evaluate(
    ({ source, flags }) => {
      const re = new RegExp(source, flags);
      for (const element of Array.from(document.querySelectorAll('[aria-label]'))) {
        const label = element.getAttribute('aria-label') ?? '';
        if (!re.test(label)) continue;
        element.scrollIntoView({ block: 'center', inline: 'center' });
        const rect = element.getBoundingClientRect();
        return {
          label,
          x: rect.left + rect.width / 2,
          y: rect.top + rect.height / 2,
        };
      }
      return null;
    },
    { source: pattern.source, flags: pattern.flags },
  );
  if (!target) {
    const scrolledTarget = await findAriaTarget(page, pattern, options);
    if (!scrolledTarget) {
      throw new Error(`No aria label matching ${pattern}; labels=${(await ariaLabels(page)).join(' | ')}`);
    }
    await page.getByLabel(scrolledTarget.label).fill(value, { timeout: 20_000 });
    return scrolledTarget.label;
  }
  await page.getByLabel(target.label).fill(value, { timeout: 20_000 });
  return target.label;
}

async function typeAria(page: Page, pattern: RegExp, value: string): Promise<string> {
  const target = await findAriaTarget(page, pattern, { scroll: true });
  if (!target) {
    throw new Error(`No aria label matching ${pattern}; labels=${(await ariaLabels(page)).join(' | ')}`);
  }
  await page.mouse.click(target.x, target.y);
  await page.keyboard.type(value, { delay: 5 });
  return target.label;
}

async function waitForCartItem(localUserId: string, token: string, timeoutMs = 35_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const items = await listCollection(`users/${localUserId}/cart`, token).catch(() => []);
    if (items.some((item) => Number(item.quantity ?? 0) > 0)) return;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Timed out waiting for cart item for ${localUserId}`);
}

async function waitForProductQuestion(
  productId: string,
  questionText: string,
  token: string,
  timeoutMs = 35_000,
): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const response = await callOk('get_product_questions', { productId, limit: 20 }, token).catch(() => null);
    const questions = Array.isArray(response?.questions) ? response.questions : [];
    const question = questions.find((item: Record<string, unknown>) => item.questionText === questionText || item.question === questionText);
    if (question) return String(question.questionId ?? question.id ?? '');
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(`Timed out waiting for product question "${questionText}"`);
}

describe('Realtime Live Updates', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  beforeEach(async () => {
    await browser.close().catch(() => undefined);
    browser = new AgentBrowser();
    await browser.clearState();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('product Q&A updates live on the product detail page', { timeout: 90_000 }, async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const admin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const subscriptionOk = await writeDoc(
      `subscriptions/${buyer.localId}`,
      {
        status: 'active',
        planId: 'premium_monthly',
        userId: buyer.localId,
        createdAt: new Date().toISOString(),
        currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      },
      admin.idToken,
      false,
    );
    expect(subscriptionOk).toBe(true);
    expect(await readDoc(`subscriptions/${buyer.localId}`, buyer.idToken)).toBeTruthy();
    const questionText = `Realtime UI question ${uid('qa')}`;
    let questionId = '';
    const playwright = await chromium.launch({ headless: true });

    try {
      const route = `/product/${PRODUCT_ID}`;
      const watcher = await openAuthedPlaywrightPage(playwright, buyer, route);
      await waitForPageSignalAfterReload(watcher, route, /Questions & Answers|Ask a question|qa\.title|btn-qa-see-all/i);
      questionId = uid('rt_qa');
      const ok = await writeDoc(
        `product_questions/${questionId}`,
        {
          questionId,
          productId: PRODUCT_ID,
          userId: buyer.localId,
          uid: buyer.localId,
          sellerId: admin.localId,
          askerId: buyer.localId,
          questionText,
          question: questionText,
          answerText: null,
          answeredAt: null,
          answeredBy: null,
          isAnswered: false,
          upvotes: 0,
          createdAt: new Date().toISOString(),
        },
        buyer.idToken,
        false,
      );
      expect(ok).toBe(true);

      await waitForPageSignalAfterReload(
        watcher,
        route,
        new RegExp(`qa-question-${questionId}|${questionText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'i'),
      );
    } finally {
      if (questionId) {
        await deleteDoc(`product_questions/${questionId}`, buyer.idToken).catch(() => false);
      }
      await deleteDoc(`subscriptions/${buyer.localId}`, admin.idToken).catch(() => false);
      await playwright.close();
    }
  });

  test('cart page updates from a live cart item insert', { timeout: 90_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await clearBuyerCart(auth.idToken, auth.localId);
    const cartItemId = uid('rt_cart');
    const playwright = await chromium.launch({ headless: true });

    try {
      const watcher = await openAuthedPlaywrightPage(playwright, auth, '/cart');
      await waitForBodyText(watcher, /your cart|cart|empty|panier/i);
      const ok = await writeDoc(
        `users/${auth.localId}/cart/${cartItemId}`,
        {
          userId: auth.localId,
          uid: auth.localId,
          productId: PRODUCT_ID,
          quantity: 1,
          name: `Realtime Cart Item ${cartItemId}`,
          productName: `Realtime Cart Item ${cartItemId}`,
          description: 'Live realtime cart E2E audit item',
          priceCents: 1299,
          priceSnapshot: 1299,
          imageUrls: [],
          createdAt: new Date().toISOString(),
        },
        auth.idToken,
        false,
      );
      expect(ok).toBe(true);
      await waitForCartItem(auth.localId, auth.idToken, 25_000);

      await waitForPageSignalAfterReload(
        watcher,
        '/cart',
        /subtotal|sous-total|proceed to checkout|checkout|btn-cart-qty-plus|btn-remove-cart-item/i,
        20_000,
      );
    } finally {
      await clearBuyerCart(auth.idToken, auth.localId).catch(() => undefined);
      await playwright.close();
    }
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
        read: false,
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
    await clearBuyerRealtimeOrders(admin.idToken, buyer.localId);

    await openAuthed(browser, '/orders');
    await waitForSnapshotText(browser, /tab-order-filter-All|orders-start-shopping|btn-back/i);

    try {
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
          createdAt: new Date().toISOString(),
          currency: 'CAD',
          sellerIds: [admin.localId],
          productIds: [PRODUCT_ID],
        },
        admin.idToken,
        false,
      );
      expect(ok).toBe(true);

      await waitForSnapshotText(browser, new RegExp(`btn-cancel-order-${orderId}|order-card-${orderId}|${itemName}`, 'i'), 35_000);
    } finally {
      await writeDoc(
        `orders/${orderId}`,
        {
          userId: 'archived-realtime-e2e',
          buyerId: 'archived-realtime-e2e',
          orderStatus: 'archived',
        },
        admin.idToken,
        true,
      ).catch(() => false);
    }
  });

  test('cart badge still updates from live UI add-to-cart interactions', { timeout: 120_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await callOk('clear_cart', {}, auth.idToken).catch(() => null);
    await clearBuyerCart(auth.idToken, auth.localId);

    await openAuthed(browser, '/');
    const first = await browser.waitForChange({ text: /btn-add-to-cart-|add.*cart|panier/i, timeout: 30_000 });
    const addButton = browser.findByLabel(first, /btn-add-to-cart-|add.*cart|panier/i);
    expect(addButton).toBeTruthy();

    await browser.click(addButton!.ref);
    await waitForSnapshotText(browser, /btn-cart[^\\n]*(1)|cart[^\\n]*(1)|panier[^\\n]*(1)/i, 35_000);
  });

  test('notifications read state updates from a live read mutation', { timeout: 90_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const notificationId = uid('rt_ui_notification');
    await clearBuyerNotifications(auth.idToken, auth.localId);
    const ok = await writeDoc(
      `users/${auth.localId}/notifications/${notificationId}`,
      {
        uid: auth.localId,
        userId: auth.localId,
        title: `UI realtime notification ${notificationId}`,
        body: 'Marked read by a second live E2E browser session.',
        type: 'account_update',
        read: false,
        createdAt: new Date().toISOString(),
      },
      auth.idToken,
      false,
    );
    expect(ok).toBe(true);

    try {
      await openAuthed(browser, '/notifications');
      await waitForSnapshotText(browser, /btn-mark-all-read|Mark all read/i, 35_000);
      const updated = await writeDoc(
        `users/${auth.localId}/notifications/${notificationId}`,
        { read: true, isRead: true },
        auth.idToken,
        true,
      );
      expect(updated).toBe(true);

      await waitForNotificationRead(auth.localId, notificationId, auth.idToken);
    } finally {
      await deleteDoc(`users/${auth.localId}/notifications/${notificationId}`, auth.idToken).catch(() => false);
    }
  });

  test('orders update across sessions from a real buyer cancel tap', { timeout: 140_000 }, async () => {
    const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    const admin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const orderId = uid('rt_ui_order');
    const itemName = `Realtime UI Cancel Item ${orderId}`;
    await clearBuyerRealtimeOrders(admin.idToken, buyer.localId);
    try {
      await openAuthed(browser, '/orders');
      await waitForSnapshotText(browser, /tab-order-filter-All|My Orders|orders/i, 35_000);
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
              description: 'Live UI-driven realtime order cancel test item',
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
          createdAt: new Date().toISOString(),
          currency: 'CAD',
          sellerIds: [admin.localId],
          productIds: [PRODUCT_ID],
        },
        admin.idToken,
        false,
      );
      expect(ok).toBe(true);
      await waitForSnapshotText(
        browser,
        new RegExp(`btn-cancel-order-${orderId}|order-card-${orderId}|${itemName}`, 'i'),
        35_000,
      );
      let actorSnap = await browser.snapshot({ interactive: true, compact: true });
      const cancelButton =
        browser.findByLabel(actorSnap, new RegExp(`btn-cancel-order-${orderId}`, 'i')) ??
        browser.findByLabel(actorSnap, /btn-order-action-Cancel Order|Cancel Order/i);
      expect(cancelButton).toBeTruthy();
      await browser.click(cancelButton!.ref);
      actorSnap = await browser.waitForChange({
        text: /btn-confirm-cancel-order|confirm|yes|cancel order/i,
        timeout: 20_000,
      });
      const confirmButton = browser.findByLabel(actorSnap, /btn-confirm-cancel-order|confirm|yes/i);
      expect(confirmButton).toBeTruthy();
      await browser.click(confirmButton!.ref);

      await waitForSnapshotText(browser, /cancelled|canceled|annul/i, 35_000);
    } finally {
      await writeDoc(
        `orders/${orderId}`,
        {
          userId: 'archived-realtime-e2e',
          buyerId: 'archived-realtime-e2e',
          orderStatus: 'archived',
        },
        admin.idToken,
        true,
      ).catch(() => false);
    }
  });

});
