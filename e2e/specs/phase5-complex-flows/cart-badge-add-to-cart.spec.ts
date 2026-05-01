import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';

import { AgentBrowser } from '../../lib/agent-browser.js';
import { callOk, deleteDoc, signIn } from '../../lib/api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS, TEST_PRODUCTS, WEB_APP_URL } from '../../lib/config.js';

async function listUserCart(token: string, localUserId: string): Promise<any[]> {
  const response = await fetch(`${ORIGNABASE_URL}/graphql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      query:
        'query($collection:String!,$filters:JSON,$limit:Int){ list(collection:$collection, filters:$filters, limit:$limit) }',
      variables: {
        collection: 'users__cart',
        filters: {
          parent_id: { _eq: `users:${localUserId}` },
        },
        limit: 25,
      },
    }),
  });

  const body = await response.json().catch(() => ({} as any));
  return Array.isArray(body?.data?.list) ? body.data.list : [];
}

function extractProductIdFromAddButton(label: string): string {
  const match = label.match(/btn-add-to-cart-(.+)$/i);
  if (!match?.[1]) {
    throw new Error(`Unable to extract product id from add-to-cart label: ${label}`);
  }
  return match[1].trim();
}

function cartQuantityForProduct(items: any[], productId: string): number {
  const bareProductId = productId.replace(/^products:/, '');
  const item = items.find((candidate) => {
    const candidateProductId = String(candidate.productId ?? '').replace(/^products:/, '');
    const candidateId = String(candidate.id ?? '').replace(/^users__cart:/, '');
    return candidateProductId === bareProductId || candidateId.includes(bareProductId);
  });
  return Number(item?.quantity ?? 0);
}

async function waitForCartQuantity(
  token: string,
  localUserId: string,
  productId: string,
  expectedQuantity: number,
  timeoutMs = 20_000,
): Promise<any[]> {
  const deadline = Date.now() + timeoutMs;
  let latest: any[] = [];
  while (Date.now() < deadline) {
    latest = await listUserCart(token, localUserId);
    if (cartQuantityForProduct(latest, productId) === expectedQuantity) {
      return latest;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  throw new Error(
    `Timed out waiting for cart quantity ${expectedQuantity} for ${productId}; latest=${JSON.stringify(latest)}`,
  );
}

async function waitForAnyCartItem(
  token: string,
  localUserId: string,
  timeoutMs = 20_000,
): Promise<any[]> {
  const deadline = Date.now() + timeoutMs;
  let latest: any[] = [];
  while (Date.now() < deadline) {
    latest = await listUserCart(token, localUserId);
    if (latest.length > 0) {
      return latest;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  throw new Error(`Timed out waiting for any cart item; latest=${JSON.stringify(latest)}`);
}

async function clearBuyerCart(token: string, localUserId: string): Promise<void> {
  await callOk('clear_cart', {}, token).catch(() => null);
  const items = await listUserCart(token, localUserId);
  await Promise.all(
    items.map((item) => {
      const id = String(item.id ?? '').split(':').pop() ?? '';
      return id ? deleteDoc(`users/${localUserId}/cart/${id}`, token).catch(() => false) : false;
    }),
  );
}

async function waitForCartControls(browser: AgentBrowser): Promise<Awaited<ReturnType<AgentBrowser['waitForChange']>>> {
  try {
    return await browser.waitForChange({
      text: /btn-cart-qty-plus|cart-item-|checkout|subtotal|total|\$/i,
      timeout: 30_000,
    });
  } catch {
    await browser.safeClick(/retry/i, 2).catch(() => false);
    await browser.open(`${WEB_APP_URL}/cart`);
    await browser.waitForFlutter();
    return browser.waitForChange({
      text: /btn-cart-qty-plus|cart-item-|checkout|subtotal|total|\$/i,
      timeout: 30_000,
    });
  }
}

describe('Cart Badge Add To Cart', () => {
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

  test('cart badge updates after adding from product detail', { timeout: 90_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await clearBuyerCart(auth.idToken, auth.localId);

    await browser.loginViaApi(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await browser.open(WEB_APP_URL);
    await browser.waitForFlutter();

    const initialSnap = await browser.waitForChange({
      text: /btn-add-to-cart-|btn-cart|input-home-search/i,
      timeout: 30_000,
    });
    const addButton = browser.findAllByLabel(initialSnap, /btn-add-to-cart-/i)[0];
    const productId = addButton ? extractProductIdFromAddButton(addButton.name) : null;

    const clicked = await browser.safeClick(/btn-add-to-cart-/i, 5);
    expect(clicked).toBe(true);

    const updatedSnap = await browser.waitForChange({
      text: /cart-badge-count-1|cart-badge-count-[2-9]|cart-badge-count-99\+|added to cart|ajouté au panier/i,
      timeout: 25_000,
    });

    const cartBadge = browser.findByLabel(updatedSnap, /cart-badge-count-/i);
    const addToCartFeedback = browser.findByLabel(updatedSnap, /added to cart|ajouté au panier/i);
    expect(cartBadge || addToCartFeedback).toBeTruthy();

    if (productId) {
      await waitForCartQuantity(auth.idToken, auth.localId, productId, 1);
    } else {
      const buyerCartItems = await waitForAnyCartItem(auth.idToken, auth.localId);
      expect(buyerCartItems.length).toBeGreaterThan(0);
    }
  });

  test('live UI add-to-cart and cart quantity controls update OrignaBase cart', { timeout: 120_000 }, async () => {
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await clearBuyerCart(auth.idToken, auth.localId);
    const productId = TEST_PRODUCTS.HIGH_STOCK;

    await browser.loginViaApi(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await browser.open(`${WEB_APP_URL}/product/${productId}`);
    await browser.waitForFlutter();

    const productSnap = await browser.waitForChange({
      text: /product_add_to_cart_button|add.*cart|panier/i,
      timeout: 30_000,
    });
    const addButton = browser.findByLabel(productSnap, /product_add_to_cart_button|add.*cart|panier/i);
    if (!addButton) throw new Error('Product detail add-to-cart button not found');

    await browser.click(addButton.ref);
    let cartItems = await waitForCartQuantity(auth.idToken, auth.localId, productId, 1);

    const secondAddClicked = await browser.safeClick(/product_add_to_cart_button|add.*cart|panier/i, 5);
    expect(secondAddClicked).toBe(true);
    cartItems = await waitForCartQuantity(auth.idToken, auth.localId, productId, 2);

    await browser.open(`${WEB_APP_URL}/cart`);
    await browser.waitForFlutter();
    const cartSnap = await waitForCartControls(browser);
    expect(/btn-cart-qty-plus|cart-item-|checkout|subtotal|total|\$/i.test(cartSnap.raw)).toBe(true);

    const plusClicked = await browser.safeClick(/btn-cart-qty-plus/i, 5);
    expect(plusClicked).toBe(true);
    cartItems = await waitForCartQuantity(auth.idToken, auth.localId, productId, 3);

    await browser.open(`${WEB_APP_URL}/cart`);
    await browser.waitForFlutter();
    await waitForCartControls(browser);
    const minusClicked = await browser.safeClick(/btn-cart-qty-minus/i, 5);
    expect(minusClicked).toBe(true);
    cartItems = await waitForCartQuantity(auth.idToken, auth.localId, productId, 2);
  });
});
