import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'bun:test';

import { AgentBrowser } from '../../lib/agent-browser.js';
import { callOk, signIn } from '../../lib/api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

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
    await callOk('clear_cart', {}, auth.idToken).catch(() => {});

    await browser.loginViaApi(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await browser.open(WEB_APP_URL);
    await browser.waitForFlutter();

    await browser.waitForChange({
      text: /btn-add-to-cart-|btn-cart|input-home-search/i,
      timeout: 30_000,
    });

    const clicked = await browser.safeClick(/btn-add-to-cart-/i, 5);
    expect(clicked).toBe(true);

    const updatedSnap = await browser.waitForChange({
      text: /cart-badge-count-1|cart-badge-count-[2-9]|cart-badge-count-99\+|added to cart|ajouté au panier/i,
      timeout: 25_000,
    });

    const cartBadge = browser.findByLabel(updatedSnap, /cart-badge-count-/i);
    const addToCartFeedback = browser.findByLabel(updatedSnap, /added to cart|ajouté au panier/i);
    expect(cartBadge || addToCartFeedback).toBeTruthy();

    const buyerCartItems = await listUserCart(auth.idToken, auth.localId);
    expect(buyerCartItems.length).toBeGreaterThan(0);
  });
});
