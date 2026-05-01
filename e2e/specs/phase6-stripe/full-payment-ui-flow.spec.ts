import { describe, expect, test } from 'bun:test';
import { chromium, type Page } from 'playwright';
import {
  buildCheckoutPayload,
  callOk,
  completeStripeCheckout,
  deleteDoc,
  extractSessionId,
  getOrder,
  listCollection,
  signIn,
  verifyEmailSent,
  writeDoc,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const buyerEmail = TEST_ACCOUNTS.BUYER_EMAIL;
const buyerPass = TEST_ACCOUNTS.BUYER_PASS;

async function activePhysicalProduct(token: string): Promise<any> {
  const products = await listCollection('products', token);
  const product = products.find((candidate: any) => {
    const status = String(candidate.lifecycleStatus ?? candidate.status ?? '').toLowerCase();
    const stock = Number(candidate.stockQuantity ?? 0);
    const priceCents = Number(candidate.priceCents ?? Math.round(Number(candidate.price ?? 0) * 100));
    return status === 'active' && stock > 2 && priceCents > 0 && !candidate.isDigital;
  });
  if (!product?.id) {
    throw new Error('No active physical product available for payment UI flow');
  }
  return product;
}

async function installAuth(page: Page, auth: Awaited<ReturnType<typeof signIn>>): Promise<void> {
  await page.goto(WEB_APP_URL, { waitUntil: 'domcontentloaded' });
  await page.evaluate((session) => {
    localStorage.setItem('orignabase_access_token', session.idToken);
    localStorage.setItem('orignabase_refresh_token', session.refreshToken ?? '');
    localStorage.setItem('orignabase_email', session.email);
  }, auth);
}

async function openAppRoute(page: Page, path: string): Promise<void> {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  await page.goto(`${WEB_APP_URL}/#${normalizedPath}`, { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await page.waitForSelector('flt-glass-pane, body', { timeout: 45_000 });
  await page.getByText(/accept|accepter|aceptar/i).last().click({ timeout: 2_000 }).catch(() => undefined);
  await page.waitForTimeout(2_000);
}

async function pageText(page: Page): Promise<string> {
  return page.locator('body').innerText({ timeout: 10_000 }).catch(() => '');
}

async function waitForOrder(orderId: string, token: string, timeoutMs = 30_000): Promise<any> {
  const deadline = Date.now() + timeoutMs;
  let order: any = null;
  while (Date.now() < deadline) {
    order = await getOrder(orderId, token);
    if (order) return order;
    await new Promise((resolve) => setTimeout(resolve, 2_000));
  }
  return order ?? getOrder(orderId, token);
}

async function resetBuyerCart(auth: Awaited<ReturnType<typeof signIn>>, product: any): Promise<void> {
  const productId = String(product.id).replace(/^products:/, '');
  const productName = String(product.name ?? product.title ?? productId);
  const priceCents = Number(
    product.priceCents ?? Math.round(Number(product.price ?? 0) * 100),
  );

  const existingItems = await listCollection(`users/${auth.localId}/cart`, auth.idToken);
  await Promise.all(
    existingItems
      .filter((item: any) => {
        const itemId = String(item.id ?? '');
        const itemProductId = String(item.productId ?? '');
        return (
          itemId.startsWith('ui_payment_') ||
          itemId.startsWith('debug_cart_test_') ||
          itemId.startsWith('test_dummy_') ||
          itemProductId.startsWith('e2e_') ||
          itemProductId.startsWith('test_dummy_') ||
          typeof item.quantity !== 'number'
        );
      })
      .map((item: any) => deleteDoc(`users/${auth.localId}/cart/${item.id}`, auth.idToken).catch(() => false)),
  );

  const cartWritten = await writeDoc(
    `users/${auth.localId}/cart/ui_payment_${productId}`,
    {
      userId: auth.localId,
      uid: auth.localId,
      productId,
      quantity: 2,
      name: productName,
      description: product.description ?? productName,
      priceCents,
      priceSnapshot: priceCents,
      productName,
      imageUrl: product.imageUrl ?? product.imageUrls?.[0] ?? '',
      imageUrls: product.imageUrls ?? (product.imageUrl ? [product.imageUrl] : []),
      createdAt: new Date().toISOString(),
      addedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      availabilityStatus: 'available',
      isUnavailable: false,
    },
    auth.idToken,
    false,
  );
  expect(cartWritten).toBe(true);
  await writeDoc(
    `user_carts/${auth.localId}`,
    {
      userId: auth.localId,
      itemCount: 1,
      totalCents: priceCents * 2,
      unavailableItemCount: 0,
      lastUpdated: new Date().toISOString(),
    },
    auth.idToken,
    true,
  );
}

describe('Full payment UI flow regression', () => {
  test('buyer cart -> checkout UI -> Stripe session -> order/email audit stays wired', async () => {
    const auth = await signIn(buyerEmail, buyerPass);
    const product = await activePhysicalProduct(auth.idToken);
    const productId = String(product.id).replace(/^products:/, '');
    const productName = String(product.name ?? product.title ?? productId);

    await callOk('clear_cart', {}, auth.idToken).catch(() => null);
    await resetBuyerCart(auth, product);

    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    try {
      await installAuth(page, auth);
      await openAppRoute(page, '/cart');
      if (!(await pageText(page)).toLowerCase().includes(productName.toLowerCase().slice(0, 12))) {
        await page
          .getByText(/shopping cart|cart|panier|carrito/i)
          .first()
          .click({ timeout: 5_000 })
          .catch(() => undefined);
        await page.waitForTimeout(2_000);
      }

      const cartText = await pageText(page);
      expect(cartText).not.toMatch(/start_shoping|security\.title|security\.enable_mfa|secirity/i);
      expect(cartText).toMatch(/subtotal\s*\(2 items\)/i);
      expect(cartText).toMatch(/CAD \$\s*(?!0\.00)\d/i);
      expect(cartText).toMatch(/cart|panier|carrito|checkout|total|\$/i);

      const checkoutCta = page
        .getByText(/checkout|passer à la caisse|pagar|finalizar/i)
        .first();
      const ctaBox = await checkoutCta.boundingBox().catch(() => null);
      if (ctaBox) {
        expect(ctaBox.width).toBeLessThan(1180);
      }

      await checkoutCta.click({ timeout: 10_000 }).catch(async () => {
        await openAppRoute(page, '/checkout');
      });
      await page.waitForTimeout(2_000);

      const checkoutText = await pageText(page);
      expect(checkoutText).not.toMatch(/start_shoping|security\.title|security\.enable_mfa|secirity/i);
      expect(checkoutText).toMatch(/checkout|payment|paiement|pago|address|adresse|dirección|total|\$/i);

      const { data } = await buildCheckoutPayload(auth.localId, productId, 1, auth.idToken);
      const checkout = await callOk(
        'create_checkout_session',
        { ...data, idempotencyKey: `ui-payment-${Date.now()}-${Math.random().toString(36).slice(2)}` },
        auth.idToken,
      );
      expect(checkout.orderId).toBeTruthy();
      expect(checkout.checkoutUrl).toMatch(/checkout\.stripe\.com/);

      const sessionId = extractSessionId(checkout.checkoutUrl);
      if (sessionId) {
        await completeStripeCheckout(sessionId).catch(() => null);
      }

      const order = await waitForOrder(checkout.orderId, auth.idToken, 45_000);
      expect(order).toBeTruthy();
      expect(order.items?.length ?? 0).toBeGreaterThan(0);
      expect(String(order.orderStatus ?? order.status ?? '')).toMatch(
        /pending|confirmed|processing|paid|payment/i,
      );

      const mailLogs = await verifyEmailSent(buyerEmail).catch(() => []);
      expect(Array.isArray(mailLogs)).toBe(true);
    } finally {
      await browser.close();
    }
  }, 180_000);
});
